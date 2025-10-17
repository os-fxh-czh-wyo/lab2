#include <buddy_system_pmm.h>
#include <pmm.h>
#include <memlayout.h>
#include <list.h>
#include <assert.h>
#include <stdio.h>

static int max_order = 0; // 最大阶数
static list_entry_t *free_list = NULL; // 存放每个order链表头的数组
// list_entry_t定义在list.h
static size_t available_page_num = 0; // 可用于分配的空闲页总数

int cal_buddy_order(size_t n) { // 找到满足2^k>=n的最小k
    int k = 0;
    size_t s = 1;
    while (s < n) { 
        s *= 2; 
        k++; 
    }
    return k;
}

static void buddy_init(void) {
    if (free_list!=NULL) {
        for (int i = 0; i <= max_order; i++) {
            list_init(&free_list[i]); // list.h中定义，初始化链表
        }
    }
    available_page_num = 0;
}

static void buddy_init_memmap(struct Page *base, size_t n) {
    // 初始化
    max_order=floor(log2(n));
    int header_size = (max_order+1)*sizeof(list_entry_t);
    int page_num = 
}

static struct Page *buddy_alloc_pages(size_t n) {
    // 分配
}

static void
buddy_free_pages(struct Page *base, size_t n) {
    assert(n > 0);

    // 1️. 计算对应的阶数（order）
    int order = cal_buddy_order(n);
    size_t block_size = (1 << order);  // 实际要释放的页数

    // 2️. 校验输入页区间是否合法
    struct Page *p = base;
    for (; p != base + block_size; p++) {
        assert(!PageReserved(p) && !PageProperty(p)); // 必须不是已被管理的页
        p->flags = 0;
        set_page_ref(p, 0);
    }

    // 3️. 校验对齐性（Buddy System关键点）
    uintptr_t base_addr = page2pa(base);
    assert((base_addr & ((block_size << PGSHIFT) - 1)) == 0); 
    // 保证 base 对齐到块大小，否则无法正确找到 buddy

    // 4️. 初始化块元信息
    base->property = block_size;
    SetPageProperty(base);
    available_page_num += block_size;

    // 5️. 自底向上递归合并伙伴块
    while (order < max_order) {
        uintptr_t buddy_addr = base_addr ^ (block_size << PGSHIFT);  // 找到伙伴物理地址
        struct Page *buddy = pa2page(buddy_addr);                    // 转换为 Page*

        // 如果伙伴不存在或已经被占用，则无法合并
        if (PageReserved(buddy) || !PageProperty(buddy))
            break;

        // 伙伴块大小必须匹配才能合并
        if (buddy->property != block_size)
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

    // 6️. 将最终合并的块挂回对应 free_list[order]
    list_entry_t *le = &free_list[order];
    while ((le = list_next(le)) != &free_list[order]) {
        struct Page *page = le2page(le, page_link);
        if (page > base) break;
    }
    list_add_before(le, &(base->page_link));

    base->property = block_size;
    SetPageProperty(base);
}


static size_t buddy_nr_free_pages(void) { // 得到可用于分配的空闲页总数
    return available_page_num;
}

static void buddy_check(void) {
    // 检查
}

const struct pmm_manager buddy_pmm_manager = { // 打包为一个pmm_manager实例，定义在pmm.h中
    .name = "buddy_system_pmm_manager",
    .init = buddy_init,
    .init_memmap = buddy_init_memmap,
    .alloc_pages = buddy_alloc_pages,
    .free_pages = buddy_free_pages,
    .nr_free_pages = buddy_nr_free_pages,
    .check = buddy_check,
};