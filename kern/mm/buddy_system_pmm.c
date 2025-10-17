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
    // 初始化
    int i=0;
    while((1UL << (i+1)) <= n){
        i++;
        max_order=i;
    }
    size_t header_size = (max_order+1)*sizeof(list_entry_t);
    size_t header_pages_num = ROUNDUP(header_size, PGSIZE) / PGSIZE;
    for(size_t i=0;i<header_pages_num;i++){
        SetPageReserved(base+i);
    }
    uintptr_t freelist_head=page2pa(base);
    free_list=(list_entry_t *)(freelist_head+va_pa_offset);
    buddy_init();
    struct Page *p=base+header_pages_num;
    size_t remain_pages=n-header_pages_num;
    while(remain_pages>0){
        size_t idx = page2ppn(p);
        int order=0;
        while((1UL << (order + 1)) <= remain_pages){
            order++;
        }
        while(order > 0 && (idx & ((1UL << order) - 1)) != 0){
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

static void buddy_free_pages(struct Page *base, size_t n) {
    // struct Page *base：要释放的块的起始页
    // size_t n：要释放的页数
    // Page相关结构和函数的定义在memlayout.h
    // 实现释放及合并
}

static size_t buddy_nr_free_pages(void) { // 得到可用于分配的空闲页总数
    return buddy_nr_free;
}

static void buddy_check(void) {
    // 检查
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

const struct pmm_manager buddy_pmm_manager = { // 打包为一个pmm_manager实例，定义在pmm.h中
    .name = "buddy_pmm_manager",
    .init = buddy_init,
    .init_memmap = buddy_init_memmap,
    .alloc_pages = buddy_alloc_pages,
    .free_pages = buddy_free_pages,
    .nr_free_pages = buddy_nr_free_pages,
    .check = buddy_check,
};