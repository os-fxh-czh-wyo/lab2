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
    while (s < n) { s <<= 1; k++; }
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
}

static struct Page *buddy_alloc_pages(size_t n) {
    // 分配
}

static void buddy_free_pages(struct Page *base, size_t n) {
    // struct Page *base：要释放的块的起始页
    // size_t n：要释放的页数
    // Page相关结构和函数的定义在memlayout.h
    // 实现释放及合并
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