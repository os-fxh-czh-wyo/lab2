# Buddy System 设计文档

## 总述

实现一个基于Buddy System算法的物理页分配器，直接接入原项目中，通过加载不同物理页分配器实例来切换不同物理页分配器。

## Buddy System算法

Buddy System算法把系统中的可用存储空间划分为存储块(Block)来进行管理, 每个存储块的大小必须是2的n次幂，n为阶数。它为每个阶维护一个空闲链表。分配时向上取整找到满足2^n大于等于需要页数的最大阶k，找不到时从更大阶分裂；释放时尽可能与它的“伙伴”合并，保持块尽可能大以减少碎片。

## 具体实现

### 框架
源码已经实现了物理页分配器的框架和接口，因此在设计伙伴系统的时候，直接使用原本的框架和定义好的数据结构。

### 初始化
- 计算最大的阶数`max_order`使得 2^max_order <= 可用页数 n，用于确定 `free_list` 数组的大小。
- 在内存起始处为 `free_list` 数组分配 `header_pages_num` 页，将这些 header 页标记为 reserved 表示存放链表头，并对 header 之后的每个 Page 进行清理，清除可能留下的残留标志，保证完全初始化。
- 将 header 的物理地址加上 `va_pa_offset` 得到内核虚地址并把 `free_list` 指向它，然后对每个 `free_list[i]` 调用 `list_init()`实现数组初始化。
- 按从左到右、尽量选取最大的对齐 2^k 块把剩余页分解为若干块，将每一页的property设置成order并加入 `free_list[order]`，同时维护 `buddy_nr_free`。

核心代码片段：

```c
static void buddy_init_memmap(struct Page *base, size_t n) {
    // ……
    // 清理页面
    for (size_t j = 0; j < header_pages_num; j++) {
        SetPageReserved(base + j);
        ClearPageProperty(base + j);
    }
    struct Page *r = base + header_pages_num;
    for (struct Page *q = r; q < base + n; q++) {
        if (PageReserved(q)) {
            ClearPageReserved(q);
        }
        ClearPageProperty(q);
        q->property = 0;
        set_page_ref(q, 0);
    }
    // 初始化数组
    uintptr_t freelist_head = page2pa(base);
    free_list = (list_entry_t *)(freelist_head + va_pa_offset);
    buddy_init();

    // 初始化伙伴系统
    struct Page *p = base + header_pages_num;
    size_t remain_pages = n - header_pages_num;
    while (remain_pages > 0) {
        size_t idx = page2ppn(p);
        int order = 0;
        while ((1UL << (order + 1)) <= remain_pages) {
            order++;
        }
        while (order > 0 && (idx & ((1UL << order) - 1)) != 0) {
            order--;
        }
        SetPageProperty(p);
        p->property = order;
        list_add(&free_list[order], &p->page_link);
        buddy_nr_free += (1UL << order);
        p += (1UL << order);
        remain_pages -= (1UL << order);
    }
}
```

### 分配
- 分配请求先计算目标阶（使 2^k >= n的最小k）。
- 在目标阶到 max_order 范围内从低到高查找第一个非空的 `free_list[i]`，如果找不到返回 NULL。
- 从找到的 `free_list[i]` 弹出块，并把 `buddy_nr_free` 减去该块大小。如果找到的阶大于目标阶，则把该块不断拆分：每次把高地址的那一半作为较低阶的空闲块放回对应链表，并更新 `buddy_nr_free`。最终剩下的低地址那一半作为分配块，清除其 Property 标志并返回。

核心代码片段：

```c
static struct Page *buddy_alloc_pages(size_t n) {
    // ……
    // 找到非空free_list[i]
    for(int i=or;i<=max_order;i++){
        if(list_empty(&free_list[i])==0){
            list_entry_t *first = list_next(&free_list[i]);
            tar = le2page(first, page_link);
            list_del(&tar->page_link);
            buddy_nr_free -= (1UL << i);
            or=i;
            break;
        }
    }
    // 分配并拆分块
    for(int i=or-1;i>=order;i--){
        size_t half=1UL<<i;
        struct Page*right=tar+half;
        SetPageProperty(right);
        right->property=i;
        list_add(&free_list[i], &right->page_link);
        buddy_nr_free += half;
    }
    if (tar == NULL){
        return NULL;
    }
    ClearPageProperty(tar);
    tar->property = 0;
    return tar;
}
```

### 释放与合并
- 释放时首先得到释放块的阶，并做对齐与合法性检查，确保所释放区域未被 Reserved/Property 标记且按块大小对齐。
- 将释放块标记为 free，然后尝试与同阶的伙伴合并。通过对基础物理页号 XOR 计算伙伴地址，检查伙伴是否在可管理范围、是否为 free 且伙伴的 property 是否等于 order。若满足则从 free_list 中删除伙伴并清除伙伴的 Property，合并为更高阶继续尝试，直到不能合并或达到 max_order。
- 合并完成后把最终的大块按阶放回对应的 free_list，并更新 `buddy_nr_free`。

核心代码片段：

```c
static void
buddy_free_pages(struct Page *base, size_t n) {
    // ……
    // 初始化块元信息
    base->property = order;
    SetPageProperty(base);
    buddy_nr_free += block_size;

    // 自底向上递归合并伙伴块
    while (order < max_order) {
        uintptr_t buddy_addr = base_addr ^ (block_size << PGSHIFT);  // 找到伙伴物理地址
        struct Page *buddy = pa2page(buddy_addr);       // 转换为 Page*

        // 如果伙伴不存在或已经被占用或大小不匹配，则无法合并
        if (PageReserved(buddy) || !PageProperty(buddy))
            break;
        if ((int)buddy->property != order)
            break;

        // 确保 buddy 在 free_list[order] 中，先移除
        list_del(&(buddy->page_link));
        ClearPageProperty(buddy);

        // 合并后选取新的 base
        if (buddy < base)
            base = buddy;
        base_addr = page2pa(base);

        // 提升阶数
        order++;
        block_size <<= 1;
    }

    // 将最终合并的块挂回对应 free_list[order]
    list_entry_t *le = &free_list[order];
    while ((le = list_next(le)) != &free_list[order]) {
        struct Page *page = le2page(le, page_link);
        if (page > base) break;
    }
    list_add_before(le, &(base->page_link));

    base->property = order;
    SetPageProperty(base);
}
```

### 检查
- `basic_check()` 会遍历每个 `free_list[i]` 的链表，验证每个块：`PageProperty(p)` 为真、`p->property == i`、块起始 ppn 按 `2^i` 对齐，并累加空闲页数，最终验证与 `buddy_nr_free` 匹配。
- `buddy_check()` 在 `basic_check()` 基础上执行一系列分配、释放操作。分配不同大小的块、释放并验证 `buddy_nr_free` 的变化以及能否一次性分配整个空闲区，以动态测试分配与合并的行为。

核心代码片段：

```c
static size_t buddy_nr_free_pages(void) { // 得到可用于分配的空闲页总数
    return buddy_nr_free;
}

static void basic_check(void) {
    // 基础检查
    assert(free_list != NULL);
    assert(max_order >= 0);
    size_t sum = 0;
    for(int i=0;i<=max_order;i++){
        list_entry_t*head=&free_list[i];
        list_entry_t*le=list_next(head);
        for(;le!=head;){
            struct Page*p=le2page(le, page_link);
            assert(PageProperty(p));
            assert((int)p->property==i);
            ppn_t idx=page2ppn(p);
            assert(idx < npage);
            assert((idx & ((1UL<<i)-1))==0);
            sum += (1UL << i);
            le=list_next(le);
        }
    }
    assert(sum == buddy_nr_free);
}

static void buddy_check(void) {
    basic_check(); // 原有结构检查
    // ……
    // 分配一些块
    size_t alloc_sizes[] = {1, 2, 3, 4, 5};  // 单位页
    int n_alloc_sizes = sizeof(alloc_sizes)/sizeof(alloc_sizes[0]);

    for (int i·=0; i<n_alloc_sizes; i++) {
        struct Page *p = buddy_alloc_pages(alloc_sizes[i]);
        assert(p != NULL);  // 确保分配成功
        blocks[num_blocks] = p;
        block_sizes[num_blocks] = alloc_sizes[i];
        num_blocks++;

        // 分配后空闲页数应减少
        size_t expected_free = total_free_before;
        for (int j=0; j<num_blocks; j++)
            expected_free -= (1UL << cal_buddy_order(block_sizes[j]));
        assert(buddy_nr_free_pages() == expected_free);
    }

    // 释放块
    for (int i=num_blocks-1; i>=0; i--) {
        buddy_free_pages(blocks[i], block_sizes[i]);
        // 释放后空闲页数增加
        total_free_before = buddy_nr_free_pages();
    }

    // 尝试分配整个空闲区（最大块）
    struct Page *max_block = buddy_alloc_pages(total_free_before);
    if (max_block != NULL) {
        assert(buddy_nr_free_pages() == 0); // 全部分配
        buddy_free_pages(max_block, total_free_before);
        assert(buddy_nr_free_pages() == total_free_before); // 释放回去
    }
   
    // 边界情况测试
    assert(buddy_alloc_pages(0) == NULL); // 分配 0 页应返回 NULL
    assert(buddy_alloc_pages(total_free_before + 1) == NULL); // 超过剩余页数应返回 NULL

    
    // 最终状态检查
    basic_check(); // 最后调用结构检查，确保链表、property 和总页数正确
}
```

## 运行结果

如下所示：

```bash
swiftiexh@DESKTOP-C6899HL:~/labcode/lab2$ make qemu
+ ld bin/kernel
riscv64-unknown-elf-objcopy bin/kernel --strip-all -O binary bin/ucore.img

OpenSBI v0.4 (Jul  2 2019 11:53:53)
   ____                    _____ ____ _____
  / __ \                  / ____|  _ \_   _|
 | |  | |_ __   ___ _ __ | (___ | |_) || |
 | |  | | '_ \ / _ \ '_ \ \___ \|  _ < | |
 | |__| | |_) |  __/ | | |____) | |_) || |_
  \____/| .__/ \___|_| |_|_____/|____/_____|
        | |
        |_|

Platform Name          : QEMU Virt Machine
Platform HART Features : RV64ACDFIMSU
Platform Max HARTs     : 8
Current Hart           : 0
Firmware Base          : 0x80000000
Firmware Size          : 112 KB
Runtime SBI Version    : 0.1

PMP0: 0x0000000080000000-0x000000008001ffff (A)
PMP1: 0x0000000000000000-0xffffffffffffffff (A,R,W,X)
DTB Init
HartID: 0
DTB Address: 0x82200000
Physical Memory from DTB:
  Base: 0x0000000080000000
  Size: 0x0000000008000000 (128 MB)
  End:  0x0000000087ffffff
DTB init completed
(THU.CST) os is loading ...
Special kernel symbols:
  entry  0xffffffffc02000d8 (virtual)
  etext  0xffffffffc0201422 (virtual)
  edata  0xffffffffc0205018 (virtual)
  end    0xffffffffc0205078 (virtual)
Kernel executable memory footprint: 20KB
memory management: buddy_pmm_manager
physcial memory map:
  memory: 0x0000000008000000, [0x0000000080000000, 0x0000000087ffffff].
check_alloc_page() succeeded!
satp virtual address: 0xffffffffc0204000
satp physical address: 0x0000000080204000
```
可以看到输出检查成功的信息，说明我们设计的Buddy System算法没问题。

