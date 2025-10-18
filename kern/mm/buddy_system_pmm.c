#include <buddy_system_pmm.h>
#include <pmm.h>
#include <memlayout.h>
#include <list.h>
#include <assert.h>
#include <stdio.h>

static int max_order = 0; // 最大阶数
static list_entry_t *free_list = NULL; // 存放每个order链表头的数组
// list_entry_t定义在list.h
static size_t buddy_nr_free = 0; // 可用于分配的空闲页总数

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
    buddy_nr_free = 0;
}

static void buddy_init_memmap(struct Page *base, size_t n) {
    // 初始化 max_order
    int i = 0;
    while ((1UL << (i + 1)) <= n) {
        i++;
        max_order = i;
    }

    size_t header_size = (max_order + 1) * sizeof(list_entry_t);
    size_t header_pages_num = (header_size + PGSIZE - 1) / PGSIZE;

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

    uintptr_t freelist_head = page2pa(base);
    free_list = (list_entry_t *)(freelist_head + va_pa_offset);
    buddy_init();

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

static struct Page *buddy_alloc_pages(size_t n) {
    // 分配
    if(n==0||n>buddy_nr_free){
        return NULL;
    }
    int or=cal_buddy_order(n),order=or;
    struct Page *tar=NULL;
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

static void
buddy_free_pages(struct Page *base, size_t n) {
    assert(n > 0);

    // 1️. 计算对应的阶数（order）
    int order = cal_buddy_order(n);
    size_t block_size = (1 << order);  // 实际要释放的页数

    // 2️. 校验输入页区间是否合法
    struct Page *p = base;
    for (; p != base + block_size; p++) {
        assert(!PageReserved(p) && !PageProperty(p));
        p->flags = 0;
        set_page_ref(p, 0);
    }

    // 3️. 校验对齐性（Buddy System关键点）
    uintptr_t base_addr = page2pa(base);
    assert((base_addr & ((block_size << PGSHIFT) - 1)) == 0); 
    // 保证 base 对齐到块大小，否则无法正确找到 buddy

    // 4️. 初始化块元信息
    base->property = order;
    SetPageProperty(base);
    buddy_nr_free += block_size;

    // 5️. 自底向上递归合并伙伴块
    while (order < max_order) {
        uintptr_t buddy_addr = base_addr ^ (block_size << PGSHIFT);  // 找到伙伴物理地址
        struct Page *buddy = pa2page(buddy_addr);                    // 转换为 Page*

        // 如果伙伴不存在或已经被占用，则无法合并
        if (PageReserved(buddy) || !PageProperty(buddy))
            break;

        // 伙伴块大小必须匹配才能合并
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

    // 6️. 将最终合并的块挂回对应 free_list[order]
    list_entry_t *le = &free_list[order];
    while ((le = list_next(le)) != &free_list[order]) {
        struct Page *page = le2page(le, page_link);
        if (page > base) break;
    }
    list_add_before(le, &(base->page_link));

    base->property = order;
    SetPageProperty(base);
}


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
    // 1. 初始化变量
    size_t total_free_before = buddy_nr_free_pages();
    struct Page *blocks[16];  // 用于记录分配的块
    size_t block_sizes[16];   // 对应块大小
    int num_blocks = 0;

    
    // 2. 分配一些块
    size_t alloc_sizes[] = {1, 2, 3, 4, 5};  // 单位页
    int n_alloc_sizes = sizeof(alloc_sizes)/sizeof(alloc_sizes[0]);

    for (int i=0; i<n_alloc_sizes; i++) {
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

    
    // 3. 释放块
    for (int i=num_blocks-1; i>=0; i--) {
        buddy_free_pages(blocks[i], block_sizes[i]);

        // 释放后空闲页数增加
        total_free_before = buddy_nr_free_pages();
    }

    // 4. 尝试分配整个空闲区（最大块）
    struct Page *max_block = buddy_alloc_pages(total_free_before);
    if (max_block != NULL) {
        assert(buddy_nr_free_pages() == 0); // 全部分配
        buddy_free_pages(max_block, total_free_before);
        assert(buddy_nr_free_pages() == total_free_before); // 释放回去
    }
   
    // 5. 边界情况测试
    assert(buddy_alloc_pages(0) == NULL); // 分配 0 页应返回 NULL
    assert(buddy_alloc_pages(total_free_before + 1) == NULL); // 超过剩余页数应返回 NULL

    
    // 6. 最终状态检查
    basic_check(); // 最后调用结构检查，确保链表、property 和总页数正确
}


const struct pmm_manager buddy_pmm_manager = { // 打包为一个pmm_manager实例，定义在pmm.h中
    .name = "buddy_pmm_manager",
    .init = buddy_init,
    .init_memmap = buddy_init_memmap,
    .alloc_pages = buddy_alloc_pages,
    .free_pages = buddy_free_pages,
    .nr_free_pages = buddy_nr_free_pages,
    .check = buddy_check,
};