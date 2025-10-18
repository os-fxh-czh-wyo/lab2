
bin/kernel:     file format elf64-littleriscv


Disassembly of section .text:

ffffffffc0200000 <kern_entry>:
    .globl kern_entry
kern_entry:
    # a0: hartid
    # a1: dtb physical address
    # save hartid and dtb address
    la t0, boot_hartid
ffffffffc0200000:	00005297          	auipc	t0,0x5
ffffffffc0200004:	00028293          	mv	t0,t0
    sd a0, 0(t0)
ffffffffc0200008:	00a2b023          	sd	a0,0(t0) # ffffffffc0205000 <boot_hartid>
    la t0, boot_dtb
ffffffffc020000c:	00005297          	auipc	t0,0x5
ffffffffc0200010:	ffc28293          	addi	t0,t0,-4 # ffffffffc0205008 <boot_dtb>
    sd a1, 0(t0)
ffffffffc0200014:	00b2b023          	sd	a1,0(t0)

    # t0 := 三级页表的虚拟地址
    lui     t0, %hi(boot_page_table_sv39)
ffffffffc0200018:	c02042b7          	lui	t0,0xc0204
    # t1 := 0xffffffff40000000 即虚实映射偏移量
    li      t1, 0xffffffffc0000000 - 0x80000000
ffffffffc020001c:	ffd0031b          	addiw	t1,zero,-3
ffffffffc0200020:	037a                	slli	t1,t1,0x1e
    # t0 减去虚实映射偏移量 0xffffffff40000000，变为三级页表的物理地址
    sub     t0, t0, t1
ffffffffc0200022:	406282b3          	sub	t0,t0,t1
    # t0 >>= 12，变为三级页表的物理页号
    srli    t0, t0, 12
ffffffffc0200026:	00c2d293          	srli	t0,t0,0xc

    # t1 := 8 << 60，设置 satp 的 MODE 字段为 Sv39
    li      t1, 8 << 60
ffffffffc020002a:	fff0031b          	addiw	t1,zero,-1
ffffffffc020002e:	137e                	slli	t1,t1,0x3f
    # 将刚才计算出的预设三级页表物理页号附加到 satp 中
    or      t0, t0, t1
ffffffffc0200030:	0062e2b3          	or	t0,t0,t1
    # 将算出的 t0(即新的MODE|页表基址物理页号) 覆盖到 satp 中
    csrw    satp, t0
ffffffffc0200034:	18029073          	csrw	satp,t0
    # 使用 sfence.vma 指令刷新 TLB
    sfence.vma
ffffffffc0200038:	12000073          	sfence.vma
    # 从此，我们给内核搭建出了一个完美的虚拟内存空间！
    #nop # 可能映射的位置有些bug。。插入一个nop
    
    # 我们在虚拟内存空间中：随意将 sp 设置为虚拟地址！
    lui sp, %hi(bootstacktop)
ffffffffc020003c:	c0204137          	lui	sp,0xc0204

    # 我们在虚拟内存空间中：随意跳转到虚拟地址！
    # 跳转到 kern_init
    lui t0, %hi(kern_init)
ffffffffc0200040:	c02002b7          	lui	t0,0xc0200
    addi t0, t0, %lo(kern_init)
ffffffffc0200044:	0d828293          	addi	t0,t0,216 # ffffffffc02000d8 <kern_init>
    jr t0
ffffffffc0200048:	8282                	jr	t0

ffffffffc020004a <print_kerninfo>:
/* *
 * print_kerninfo - print the information about kernel, including the location
 * of kernel entry, the start addresses of data and text segements, the start
 * address of free memory and how many memory that kernel has used.
 * */
void print_kerninfo(void) {
ffffffffc020004a:	1141                	addi	sp,sp,-16
    extern char etext[], edata[], end[];
    cprintf("Special kernel symbols:\n");
ffffffffc020004c:	00001517          	auipc	a0,0x1
ffffffffc0200050:	3dc50513          	addi	a0,a0,988 # ffffffffc0201428 <etext+0x6>
void print_kerninfo(void) {
ffffffffc0200054:	e406                	sd	ra,8(sp)
    cprintf("Special kernel symbols:\n");
ffffffffc0200056:	0f6000ef          	jal	ra,ffffffffc020014c <cprintf>
    cprintf("  entry  0x%016lx (virtual)\n", (uintptr_t)kern_init);
ffffffffc020005a:	00000597          	auipc	a1,0x0
ffffffffc020005e:	07e58593          	addi	a1,a1,126 # ffffffffc02000d8 <kern_init>
ffffffffc0200062:	00001517          	auipc	a0,0x1
ffffffffc0200066:	3e650513          	addi	a0,a0,998 # ffffffffc0201448 <etext+0x26>
ffffffffc020006a:	0e2000ef          	jal	ra,ffffffffc020014c <cprintf>
    cprintf("  etext  0x%016lx (virtual)\n", etext);
ffffffffc020006e:	00001597          	auipc	a1,0x1
ffffffffc0200072:	3b458593          	addi	a1,a1,948 # ffffffffc0201422 <etext>
ffffffffc0200076:	00001517          	auipc	a0,0x1
ffffffffc020007a:	3f250513          	addi	a0,a0,1010 # ffffffffc0201468 <etext+0x46>
ffffffffc020007e:	0ce000ef          	jal	ra,ffffffffc020014c <cprintf>
    cprintf("  edata  0x%016lx (virtual)\n", edata);
ffffffffc0200082:	00005597          	auipc	a1,0x5
ffffffffc0200086:	f9658593          	addi	a1,a1,-106 # ffffffffc0205018 <is_panic>
ffffffffc020008a:	00001517          	auipc	a0,0x1
ffffffffc020008e:	3fe50513          	addi	a0,a0,1022 # ffffffffc0201488 <etext+0x66>
ffffffffc0200092:	0ba000ef          	jal	ra,ffffffffc020014c <cprintf>
    cprintf("  end    0x%016lx (virtual)\n", end);
ffffffffc0200096:	00005597          	auipc	a1,0x5
ffffffffc020009a:	fe258593          	addi	a1,a1,-30 # ffffffffc0205078 <end>
ffffffffc020009e:	00001517          	auipc	a0,0x1
ffffffffc02000a2:	40a50513          	addi	a0,a0,1034 # ffffffffc02014a8 <etext+0x86>
ffffffffc02000a6:	0a6000ef          	jal	ra,ffffffffc020014c <cprintf>
    cprintf("Kernel executable memory footprint: %dKB\n",
            (end - (char*)kern_init + 1023) / 1024);
ffffffffc02000aa:	00005597          	auipc	a1,0x5
ffffffffc02000ae:	3cd58593          	addi	a1,a1,973 # ffffffffc0205477 <end+0x3ff>
ffffffffc02000b2:	00000797          	auipc	a5,0x0
ffffffffc02000b6:	02678793          	addi	a5,a5,38 # ffffffffc02000d8 <kern_init>
ffffffffc02000ba:	40f587b3          	sub	a5,a1,a5
    cprintf("Kernel executable memory footprint: %dKB\n",
ffffffffc02000be:	43f7d593          	srai	a1,a5,0x3f
}
ffffffffc02000c2:	60a2                	ld	ra,8(sp)
    cprintf("Kernel executable memory footprint: %dKB\n",
ffffffffc02000c4:	3ff5f593          	andi	a1,a1,1023
ffffffffc02000c8:	95be                	add	a1,a1,a5
ffffffffc02000ca:	85a9                	srai	a1,a1,0xa
ffffffffc02000cc:	00001517          	auipc	a0,0x1
ffffffffc02000d0:	3fc50513          	addi	a0,a0,1020 # ffffffffc02014c8 <etext+0xa6>
}
ffffffffc02000d4:	0141                	addi	sp,sp,16
    cprintf("Kernel executable memory footprint: %dKB\n",
ffffffffc02000d6:	a89d                	j	ffffffffc020014c <cprintf>

ffffffffc02000d8 <kern_init>:

int kern_init(void) {
    extern char edata[], end[];
    memset(edata, 0, end - edata);
ffffffffc02000d8:	00005517          	auipc	a0,0x5
ffffffffc02000dc:	f4050513          	addi	a0,a0,-192 # ffffffffc0205018 <is_panic>
ffffffffc02000e0:	00005617          	auipc	a2,0x5
ffffffffc02000e4:	f9860613          	addi	a2,a2,-104 # ffffffffc0205078 <end>
int kern_init(void) {
ffffffffc02000e8:	1141                	addi	sp,sp,-16
    memset(edata, 0, end - edata);
ffffffffc02000ea:	8e09                	sub	a2,a2,a0
ffffffffc02000ec:	4581                	li	a1,0
int kern_init(void) {
ffffffffc02000ee:	e406                	sd	ra,8(sp)
    memset(edata, 0, end - edata);
ffffffffc02000f0:	320010ef          	jal	ra,ffffffffc0201410 <memset>
    dtb_init();
ffffffffc02000f4:	12c000ef          	jal	ra,ffffffffc0200220 <dtb_init>
    cons_init();  // init the console
ffffffffc02000f8:	11e000ef          	jal	ra,ffffffffc0200216 <cons_init>
    const char *message = "(THU.CST) os is loading ...\0";
    //cprintf("%s\n\n", message);
    cputs(message);
ffffffffc02000fc:	00001517          	auipc	a0,0x1
ffffffffc0200100:	3fc50513          	addi	a0,a0,1020 # ffffffffc02014f8 <etext+0xd6>
ffffffffc0200104:	07e000ef          	jal	ra,ffffffffc0200182 <cputs>

    print_kerninfo();
ffffffffc0200108:	f43ff0ef          	jal	ra,ffffffffc020004a <print_kerninfo>

    // grade_backtrace();
    pmm_init();  // init physical memory management
ffffffffc020010c:	4ab000ef          	jal	ra,ffffffffc0200db6 <pmm_init>

    /* do nothing */
    while (1)
ffffffffc0200110:	a001                	j	ffffffffc0200110 <kern_init+0x38>

ffffffffc0200112 <cputch>:
/* *
 * cputch - writes a single character @c to stdout, and it will
 * increace the value of counter pointed by @cnt.
 * */
static void
cputch(int c, int *cnt) {
ffffffffc0200112:	1141                	addi	sp,sp,-16
ffffffffc0200114:	e022                	sd	s0,0(sp)
ffffffffc0200116:	e406                	sd	ra,8(sp)
ffffffffc0200118:	842e                	mv	s0,a1
    cons_putc(c);
ffffffffc020011a:	0fe000ef          	jal	ra,ffffffffc0200218 <cons_putc>
    (*cnt) ++;
ffffffffc020011e:	401c                	lw	a5,0(s0)
}
ffffffffc0200120:	60a2                	ld	ra,8(sp)
    (*cnt) ++;
ffffffffc0200122:	2785                	addiw	a5,a5,1
ffffffffc0200124:	c01c                	sw	a5,0(s0)
}
ffffffffc0200126:	6402                	ld	s0,0(sp)
ffffffffc0200128:	0141                	addi	sp,sp,16
ffffffffc020012a:	8082                	ret

ffffffffc020012c <vcprintf>:
 *
 * Call this function if you are already dealing with a va_list.
 * Or you probably want cprintf() instead.
 * */
int
vcprintf(const char *fmt, va_list ap) {
ffffffffc020012c:	1101                	addi	sp,sp,-32
ffffffffc020012e:	862a                	mv	a2,a0
ffffffffc0200130:	86ae                	mv	a3,a1
    int cnt = 0;
    vprintfmt((void*)cputch, &cnt, fmt, ap);
ffffffffc0200132:	00000517          	auipc	a0,0x0
ffffffffc0200136:	fe050513          	addi	a0,a0,-32 # ffffffffc0200112 <cputch>
ffffffffc020013a:	006c                	addi	a1,sp,12
vcprintf(const char *fmt, va_list ap) {
ffffffffc020013c:	ec06                	sd	ra,24(sp)
    int cnt = 0;
ffffffffc020013e:	c602                	sw	zero,12(sp)
    vprintfmt((void*)cputch, &cnt, fmt, ap);
ffffffffc0200140:	6bb000ef          	jal	ra,ffffffffc0200ffa <vprintfmt>
    return cnt;
}
ffffffffc0200144:	60e2                	ld	ra,24(sp)
ffffffffc0200146:	4532                	lw	a0,12(sp)
ffffffffc0200148:	6105                	addi	sp,sp,32
ffffffffc020014a:	8082                	ret

ffffffffc020014c <cprintf>:
 *
 * The return value is the number of characters which would be
 * written to stdout.
 * */
int
cprintf(const char *fmt, ...) {
ffffffffc020014c:	711d                	addi	sp,sp,-96
    va_list ap;
    int cnt;
    va_start(ap, fmt);
ffffffffc020014e:	02810313          	addi	t1,sp,40 # ffffffffc0204028 <boot_page_table_sv39+0x28>
cprintf(const char *fmt, ...) {
ffffffffc0200152:	8e2a                	mv	t3,a0
ffffffffc0200154:	f42e                	sd	a1,40(sp)
ffffffffc0200156:	f832                	sd	a2,48(sp)
ffffffffc0200158:	fc36                	sd	a3,56(sp)
    vprintfmt((void*)cputch, &cnt, fmt, ap);
ffffffffc020015a:	00000517          	auipc	a0,0x0
ffffffffc020015e:	fb850513          	addi	a0,a0,-72 # ffffffffc0200112 <cputch>
ffffffffc0200162:	004c                	addi	a1,sp,4
ffffffffc0200164:	869a                	mv	a3,t1
ffffffffc0200166:	8672                	mv	a2,t3
cprintf(const char *fmt, ...) {
ffffffffc0200168:	ec06                	sd	ra,24(sp)
ffffffffc020016a:	e0ba                	sd	a4,64(sp)
ffffffffc020016c:	e4be                	sd	a5,72(sp)
ffffffffc020016e:	e8c2                	sd	a6,80(sp)
ffffffffc0200170:	ecc6                	sd	a7,88(sp)
    va_start(ap, fmt);
ffffffffc0200172:	e41a                	sd	t1,8(sp)
    int cnt = 0;
ffffffffc0200174:	c202                	sw	zero,4(sp)
    vprintfmt((void*)cputch, &cnt, fmt, ap);
ffffffffc0200176:	685000ef          	jal	ra,ffffffffc0200ffa <vprintfmt>
    cnt = vcprintf(fmt, ap);
    va_end(ap);
    return cnt;
}
ffffffffc020017a:	60e2                	ld	ra,24(sp)
ffffffffc020017c:	4512                	lw	a0,4(sp)
ffffffffc020017e:	6125                	addi	sp,sp,96
ffffffffc0200180:	8082                	ret

ffffffffc0200182 <cputs>:
/* *
 * cputs- writes the string pointed by @str to stdout and
 * appends a newline character.
 * */
int
cputs(const char *str) {
ffffffffc0200182:	1101                	addi	sp,sp,-32
ffffffffc0200184:	e822                	sd	s0,16(sp)
ffffffffc0200186:	ec06                	sd	ra,24(sp)
ffffffffc0200188:	e426                	sd	s1,8(sp)
ffffffffc020018a:	842a                	mv	s0,a0
    int cnt = 0;
    char c;
    while ((c = *str ++) != '\0') {
ffffffffc020018c:	00054503          	lbu	a0,0(a0)
ffffffffc0200190:	c51d                	beqz	a0,ffffffffc02001be <cputs+0x3c>
ffffffffc0200192:	0405                	addi	s0,s0,1
ffffffffc0200194:	4485                	li	s1,1
ffffffffc0200196:	9c81                	subw	s1,s1,s0
    cons_putc(c);
ffffffffc0200198:	080000ef          	jal	ra,ffffffffc0200218 <cons_putc>
    while ((c = *str ++) != '\0') {
ffffffffc020019c:	00044503          	lbu	a0,0(s0)
ffffffffc02001a0:	008487bb          	addw	a5,s1,s0
ffffffffc02001a4:	0405                	addi	s0,s0,1
ffffffffc02001a6:	f96d                	bnez	a0,ffffffffc0200198 <cputs+0x16>
    (*cnt) ++;
ffffffffc02001a8:	0017841b          	addiw	s0,a5,1
    cons_putc(c);
ffffffffc02001ac:	4529                	li	a0,10
ffffffffc02001ae:	06a000ef          	jal	ra,ffffffffc0200218 <cons_putc>
        cputch(c, &cnt);
    }
    cputch('\n', &cnt);
    return cnt;
}
ffffffffc02001b2:	60e2                	ld	ra,24(sp)
ffffffffc02001b4:	8522                	mv	a0,s0
ffffffffc02001b6:	6442                	ld	s0,16(sp)
ffffffffc02001b8:	64a2                	ld	s1,8(sp)
ffffffffc02001ba:	6105                	addi	sp,sp,32
ffffffffc02001bc:	8082                	ret
    while ((c = *str ++) != '\0') {
ffffffffc02001be:	4405                	li	s0,1
ffffffffc02001c0:	b7f5                	j	ffffffffc02001ac <cputs+0x2a>

ffffffffc02001c2 <__panic>:
 * __panic - __panic is called on unresolvable fatal errors. it prints
 * "panic: 'message'", and then enters the kernel monitor.
 * */
void
__panic(const char *file, int line, const char *fmt, ...) {
    if (is_panic) {
ffffffffc02001c2:	00005317          	auipc	t1,0x5
ffffffffc02001c6:	e5630313          	addi	t1,t1,-426 # ffffffffc0205018 <is_panic>
ffffffffc02001ca:	00032e03          	lw	t3,0(t1)
__panic(const char *file, int line, const char *fmt, ...) {
ffffffffc02001ce:	715d                	addi	sp,sp,-80
ffffffffc02001d0:	ec06                	sd	ra,24(sp)
ffffffffc02001d2:	e822                	sd	s0,16(sp)
ffffffffc02001d4:	f436                	sd	a3,40(sp)
ffffffffc02001d6:	f83a                	sd	a4,48(sp)
ffffffffc02001d8:	fc3e                	sd	a5,56(sp)
ffffffffc02001da:	e0c2                	sd	a6,64(sp)
ffffffffc02001dc:	e4c6                	sd	a7,72(sp)
    if (is_panic) {
ffffffffc02001de:	000e0363          	beqz	t3,ffffffffc02001e4 <__panic+0x22>
    vcprintf(fmt, ap);
    cprintf("\n");
    va_end(ap);

panic_dead:
    while (1) {
ffffffffc02001e2:	a001                	j	ffffffffc02001e2 <__panic+0x20>
    is_panic = 1;
ffffffffc02001e4:	4785                	li	a5,1
ffffffffc02001e6:	00f32023          	sw	a5,0(t1)
    va_start(ap, fmt);
ffffffffc02001ea:	8432                	mv	s0,a2
ffffffffc02001ec:	103c                	addi	a5,sp,40
    cprintf("kernel panic at %s:%d:\n    ", file, line);
ffffffffc02001ee:	862e                	mv	a2,a1
ffffffffc02001f0:	85aa                	mv	a1,a0
ffffffffc02001f2:	00001517          	auipc	a0,0x1
ffffffffc02001f6:	32650513          	addi	a0,a0,806 # ffffffffc0201518 <etext+0xf6>
    va_start(ap, fmt);
ffffffffc02001fa:	e43e                	sd	a5,8(sp)
    cprintf("kernel panic at %s:%d:\n    ", file, line);
ffffffffc02001fc:	f51ff0ef          	jal	ra,ffffffffc020014c <cprintf>
    vcprintf(fmt, ap);
ffffffffc0200200:	65a2                	ld	a1,8(sp)
ffffffffc0200202:	8522                	mv	a0,s0
ffffffffc0200204:	f29ff0ef          	jal	ra,ffffffffc020012c <vcprintf>
    cprintf("\n");
ffffffffc0200208:	00001517          	auipc	a0,0x1
ffffffffc020020c:	2e850513          	addi	a0,a0,744 # ffffffffc02014f0 <etext+0xce>
ffffffffc0200210:	f3dff0ef          	jal	ra,ffffffffc020014c <cprintf>
ffffffffc0200214:	b7f9                	j	ffffffffc02001e2 <__panic+0x20>

ffffffffc0200216 <cons_init>:

/* serial_intr - try to feed input characters from serial port */
void serial_intr(void) {}

/* cons_init - initializes the console devices */
void cons_init(void) {}
ffffffffc0200216:	8082                	ret

ffffffffc0200218 <cons_putc>:

/* cons_putc - print a single character @c to console devices */
void cons_putc(int c) { sbi_console_putchar((unsigned char)c); }
ffffffffc0200218:	0ff57513          	andi	a0,a0,255
ffffffffc020021c:	1600106f          	j	ffffffffc020137c <sbi_console_putchar>

ffffffffc0200220 <dtb_init>:

// 保存解析出的系统物理内存信息
static uint64_t memory_base = 0;
static uint64_t memory_size = 0;

void dtb_init(void) {
ffffffffc0200220:	7119                	addi	sp,sp,-128
    cprintf("DTB Init\n");
ffffffffc0200222:	00001517          	auipc	a0,0x1
ffffffffc0200226:	31650513          	addi	a0,a0,790 # ffffffffc0201538 <etext+0x116>
void dtb_init(void) {
ffffffffc020022a:	fc86                	sd	ra,120(sp)
ffffffffc020022c:	f8a2                	sd	s0,112(sp)
ffffffffc020022e:	e8d2                	sd	s4,80(sp)
ffffffffc0200230:	f4a6                	sd	s1,104(sp)
ffffffffc0200232:	f0ca                	sd	s2,96(sp)
ffffffffc0200234:	ecce                	sd	s3,88(sp)
ffffffffc0200236:	e4d6                	sd	s5,72(sp)
ffffffffc0200238:	e0da                	sd	s6,64(sp)
ffffffffc020023a:	fc5e                	sd	s7,56(sp)
ffffffffc020023c:	f862                	sd	s8,48(sp)
ffffffffc020023e:	f466                	sd	s9,40(sp)
ffffffffc0200240:	f06a                	sd	s10,32(sp)
ffffffffc0200242:	ec6e                	sd	s11,24(sp)
    cprintf("DTB Init\n");
ffffffffc0200244:	f09ff0ef          	jal	ra,ffffffffc020014c <cprintf>
    cprintf("HartID: %ld\n", boot_hartid);
ffffffffc0200248:	00005597          	auipc	a1,0x5
ffffffffc020024c:	db85b583          	ld	a1,-584(a1) # ffffffffc0205000 <boot_hartid>
ffffffffc0200250:	00001517          	auipc	a0,0x1
ffffffffc0200254:	2f850513          	addi	a0,a0,760 # ffffffffc0201548 <etext+0x126>
ffffffffc0200258:	ef5ff0ef          	jal	ra,ffffffffc020014c <cprintf>
    cprintf("DTB Address: 0x%lx\n", boot_dtb);
ffffffffc020025c:	00005417          	auipc	s0,0x5
ffffffffc0200260:	dac40413          	addi	s0,s0,-596 # ffffffffc0205008 <boot_dtb>
ffffffffc0200264:	600c                	ld	a1,0(s0)
ffffffffc0200266:	00001517          	auipc	a0,0x1
ffffffffc020026a:	2f250513          	addi	a0,a0,754 # ffffffffc0201558 <etext+0x136>
ffffffffc020026e:	edfff0ef          	jal	ra,ffffffffc020014c <cprintf>
    
    if (boot_dtb == 0) {
ffffffffc0200272:	00043a03          	ld	s4,0(s0)
        cprintf("Error: DTB address is null\n");
ffffffffc0200276:	00001517          	auipc	a0,0x1
ffffffffc020027a:	2fa50513          	addi	a0,a0,762 # ffffffffc0201570 <etext+0x14e>
    if (boot_dtb == 0) {
ffffffffc020027e:	120a0463          	beqz	s4,ffffffffc02003a6 <dtb_init+0x186>
        return;
    }
    
    // 转换为虚拟地址
    uintptr_t dtb_vaddr = boot_dtb + PHYSICAL_MEMORY_OFFSET;
ffffffffc0200282:	57f5                	li	a5,-3
ffffffffc0200284:	07fa                	slli	a5,a5,0x1e
ffffffffc0200286:	00fa0733          	add	a4,s4,a5
    const struct fdt_header *header = (const struct fdt_header *)dtb_vaddr;
    
    // 验证DTB
    uint32_t magic = fdt32_to_cpu(header->magic);
ffffffffc020028a:	431c                	lw	a5,0(a4)
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020028c:	00ff0637          	lui	a2,0xff0
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200290:	6b41                	lui	s6,0x10
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200292:	0087d59b          	srliw	a1,a5,0x8
ffffffffc0200296:	0187969b          	slliw	a3,a5,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020029a:	0187d51b          	srliw	a0,a5,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020029e:	0105959b          	slliw	a1,a1,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02002a2:	0107d79b          	srliw	a5,a5,0x10
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02002a6:	8df1                	and	a1,a1,a2
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02002a8:	8ec9                	or	a3,a3,a0
ffffffffc02002aa:	0087979b          	slliw	a5,a5,0x8
ffffffffc02002ae:	1b7d                	addi	s6,s6,-1
ffffffffc02002b0:	0167f7b3          	and	a5,a5,s6
ffffffffc02002b4:	8dd5                	or	a1,a1,a3
ffffffffc02002b6:	8ddd                	or	a1,a1,a5
    if (magic != 0xd00dfeed) {
ffffffffc02002b8:	d00e07b7          	lui	a5,0xd00e0
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02002bc:	2581                	sext.w	a1,a1
    if (magic != 0xd00dfeed) {
ffffffffc02002be:	eed78793          	addi	a5,a5,-275 # ffffffffd00dfeed <end+0xfedae75>
ffffffffc02002c2:	10f59163          	bne	a1,a5,ffffffffc02003c4 <dtb_init+0x1a4>
        return;
    }
    
    // 提取内存信息
    uint64_t mem_base, mem_size;
    if (extract_memory_info(dtb_vaddr, header, &mem_base, &mem_size) == 0) {
ffffffffc02002c6:	471c                	lw	a5,8(a4)
ffffffffc02002c8:	4754                	lw	a3,12(a4)
    int in_memory_node = 0;
ffffffffc02002ca:	4c81                	li	s9,0
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02002cc:	0087d59b          	srliw	a1,a5,0x8
ffffffffc02002d0:	0086d51b          	srliw	a0,a3,0x8
ffffffffc02002d4:	0186941b          	slliw	s0,a3,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02002d8:	0186d89b          	srliw	a7,a3,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02002dc:	01879a1b          	slliw	s4,a5,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02002e0:	0187d81b          	srliw	a6,a5,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02002e4:	0105151b          	slliw	a0,a0,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02002e8:	0106d69b          	srliw	a3,a3,0x10
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02002ec:	0105959b          	slliw	a1,a1,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02002f0:	0107d79b          	srliw	a5,a5,0x10
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02002f4:	8d71                	and	a0,a0,a2
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02002f6:	01146433          	or	s0,s0,a7
ffffffffc02002fa:	0086969b          	slliw	a3,a3,0x8
ffffffffc02002fe:	010a6a33          	or	s4,s4,a6
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200302:	8e6d                	and	a2,a2,a1
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200304:	0087979b          	slliw	a5,a5,0x8
ffffffffc0200308:	8c49                	or	s0,s0,a0
ffffffffc020030a:	0166f6b3          	and	a3,a3,s6
ffffffffc020030e:	00ca6a33          	or	s4,s4,a2
ffffffffc0200312:	0167f7b3          	and	a5,a5,s6
ffffffffc0200316:	8c55                	or	s0,s0,a3
ffffffffc0200318:	00fa6a33          	or	s4,s4,a5
    const char *strings_base = (const char *)(dtb_vaddr + strings_offset);
ffffffffc020031c:	1402                	slli	s0,s0,0x20
    const uint32_t *struct_ptr = (const uint32_t *)(dtb_vaddr + struct_offset);
ffffffffc020031e:	1a02                	slli	s4,s4,0x20
    const char *strings_base = (const char *)(dtb_vaddr + strings_offset);
ffffffffc0200320:	9001                	srli	s0,s0,0x20
    const uint32_t *struct_ptr = (const uint32_t *)(dtb_vaddr + struct_offset);
ffffffffc0200322:	020a5a13          	srli	s4,s4,0x20
    const char *strings_base = (const char *)(dtb_vaddr + strings_offset);
ffffffffc0200326:	943a                	add	s0,s0,a4
    const uint32_t *struct_ptr = (const uint32_t *)(dtb_vaddr + struct_offset);
ffffffffc0200328:	9a3a                	add	s4,s4,a4
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020032a:	00ff0c37          	lui	s8,0xff0
        switch (token) {
ffffffffc020032e:	4b8d                	li	s7,3
                if (in_memory_node && strcmp(prop_name, "reg") == 0 && prop_len >= 16) {
ffffffffc0200330:	00001917          	auipc	s2,0x1
ffffffffc0200334:	29090913          	addi	s2,s2,656 # ffffffffc02015c0 <etext+0x19e>
ffffffffc0200338:	49bd                	li	s3,15
        switch (token) {
ffffffffc020033a:	4d91                	li	s11,4
ffffffffc020033c:	4d05                	li	s10,1
                if (strncmp(name, "memory", 6) == 0) {
ffffffffc020033e:	00001497          	auipc	s1,0x1
ffffffffc0200342:	27a48493          	addi	s1,s1,634 # ffffffffc02015b8 <etext+0x196>
        uint32_t token = fdt32_to_cpu(*struct_ptr++);
ffffffffc0200346:	000a2703          	lw	a4,0(s4)
ffffffffc020034a:	004a0a93          	addi	s5,s4,4
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020034e:	0087569b          	srliw	a3,a4,0x8
ffffffffc0200352:	0187179b          	slliw	a5,a4,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200356:	0187561b          	srliw	a2,a4,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020035a:	0106969b          	slliw	a3,a3,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020035e:	0107571b          	srliw	a4,a4,0x10
ffffffffc0200362:	8fd1                	or	a5,a5,a2
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200364:	0186f6b3          	and	a3,a3,s8
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200368:	0087171b          	slliw	a4,a4,0x8
ffffffffc020036c:	8fd5                	or	a5,a5,a3
ffffffffc020036e:	00eb7733          	and	a4,s6,a4
ffffffffc0200372:	8fd9                	or	a5,a5,a4
ffffffffc0200374:	2781                	sext.w	a5,a5
        switch (token) {
ffffffffc0200376:	09778c63          	beq	a5,s7,ffffffffc020040e <dtb_init+0x1ee>
ffffffffc020037a:	00fbea63          	bltu	s7,a5,ffffffffc020038e <dtb_init+0x16e>
ffffffffc020037e:	07a78663          	beq	a5,s10,ffffffffc02003ea <dtb_init+0x1ca>
ffffffffc0200382:	4709                	li	a4,2
ffffffffc0200384:	00e79763          	bne	a5,a4,ffffffffc0200392 <dtb_init+0x172>
ffffffffc0200388:	4c81                	li	s9,0
ffffffffc020038a:	8a56                	mv	s4,s5
ffffffffc020038c:	bf6d                	j	ffffffffc0200346 <dtb_init+0x126>
ffffffffc020038e:	ffb78ee3          	beq	a5,s11,ffffffffc020038a <dtb_init+0x16a>
        cprintf("  End:  0x%016lx\n", mem_base + mem_size - 1);
        // 保存到全局变量，供 PMM 查询
        memory_base = mem_base;
        memory_size = mem_size;
    } else {
        cprintf("Warning: Could not extract memory info from DTB\n");
ffffffffc0200392:	00001517          	auipc	a0,0x1
ffffffffc0200396:	2a650513          	addi	a0,a0,678 # ffffffffc0201638 <etext+0x216>
ffffffffc020039a:	db3ff0ef          	jal	ra,ffffffffc020014c <cprintf>
    }
    cprintf("DTB init completed\n");
ffffffffc020039e:	00001517          	auipc	a0,0x1
ffffffffc02003a2:	2d250513          	addi	a0,a0,722 # ffffffffc0201670 <etext+0x24e>
}
ffffffffc02003a6:	7446                	ld	s0,112(sp)
ffffffffc02003a8:	70e6                	ld	ra,120(sp)
ffffffffc02003aa:	74a6                	ld	s1,104(sp)
ffffffffc02003ac:	7906                	ld	s2,96(sp)
ffffffffc02003ae:	69e6                	ld	s3,88(sp)
ffffffffc02003b0:	6a46                	ld	s4,80(sp)
ffffffffc02003b2:	6aa6                	ld	s5,72(sp)
ffffffffc02003b4:	6b06                	ld	s6,64(sp)
ffffffffc02003b6:	7be2                	ld	s7,56(sp)
ffffffffc02003b8:	7c42                	ld	s8,48(sp)
ffffffffc02003ba:	7ca2                	ld	s9,40(sp)
ffffffffc02003bc:	7d02                	ld	s10,32(sp)
ffffffffc02003be:	6de2                	ld	s11,24(sp)
ffffffffc02003c0:	6109                	addi	sp,sp,128
    cprintf("DTB init completed\n");
ffffffffc02003c2:	b369                	j	ffffffffc020014c <cprintf>
}
ffffffffc02003c4:	7446                	ld	s0,112(sp)
ffffffffc02003c6:	70e6                	ld	ra,120(sp)
ffffffffc02003c8:	74a6                	ld	s1,104(sp)
ffffffffc02003ca:	7906                	ld	s2,96(sp)
ffffffffc02003cc:	69e6                	ld	s3,88(sp)
ffffffffc02003ce:	6a46                	ld	s4,80(sp)
ffffffffc02003d0:	6aa6                	ld	s5,72(sp)
ffffffffc02003d2:	6b06                	ld	s6,64(sp)
ffffffffc02003d4:	7be2                	ld	s7,56(sp)
ffffffffc02003d6:	7c42                	ld	s8,48(sp)
ffffffffc02003d8:	7ca2                	ld	s9,40(sp)
ffffffffc02003da:	7d02                	ld	s10,32(sp)
ffffffffc02003dc:	6de2                	ld	s11,24(sp)
        cprintf("Error: Invalid DTB magic number: 0x%x\n", magic);
ffffffffc02003de:	00001517          	auipc	a0,0x1
ffffffffc02003e2:	1b250513          	addi	a0,a0,434 # ffffffffc0201590 <etext+0x16e>
}
ffffffffc02003e6:	6109                	addi	sp,sp,128
        cprintf("Error: Invalid DTB magic number: 0x%x\n", magic);
ffffffffc02003e8:	b395                	j	ffffffffc020014c <cprintf>
                int name_len = strlen(name);
ffffffffc02003ea:	8556                	mv	a0,s5
ffffffffc02003ec:	7ab000ef          	jal	ra,ffffffffc0201396 <strlen>
ffffffffc02003f0:	8a2a                	mv	s4,a0
                if (strncmp(name, "memory", 6) == 0) {
ffffffffc02003f2:	4619                	li	a2,6
ffffffffc02003f4:	85a6                	mv	a1,s1
ffffffffc02003f6:	8556                	mv	a0,s5
                int name_len = strlen(name);
ffffffffc02003f8:	2a01                	sext.w	s4,s4
                if (strncmp(name, "memory", 6) == 0) {
ffffffffc02003fa:	7f1000ef          	jal	ra,ffffffffc02013ea <strncmp>
ffffffffc02003fe:	e111                	bnez	a0,ffffffffc0200402 <dtb_init+0x1e2>
                    in_memory_node = 1;
ffffffffc0200400:	4c85                	li	s9,1
                struct_ptr = (const uint32_t *)(((uintptr_t)struct_ptr + name_len + 4) & ~3);
ffffffffc0200402:	0a91                	addi	s5,s5,4
ffffffffc0200404:	9ad2                	add	s5,s5,s4
ffffffffc0200406:	ffcafa93          	andi	s5,s5,-4
        switch (token) {
ffffffffc020040a:	8a56                	mv	s4,s5
ffffffffc020040c:	bf2d                	j	ffffffffc0200346 <dtb_init+0x126>
                uint32_t prop_len = fdt32_to_cpu(*struct_ptr++);
ffffffffc020040e:	004a2783          	lw	a5,4(s4)
                uint32_t prop_nameoff = fdt32_to_cpu(*struct_ptr++);
ffffffffc0200412:	00ca0693          	addi	a3,s4,12
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200416:	0087d71b          	srliw	a4,a5,0x8
ffffffffc020041a:	01879a9b          	slliw	s5,a5,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020041e:	0187d61b          	srliw	a2,a5,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200422:	0107171b          	slliw	a4,a4,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200426:	0107d79b          	srliw	a5,a5,0x10
ffffffffc020042a:	00caeab3          	or	s5,s5,a2
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020042e:	01877733          	and	a4,a4,s8
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200432:	0087979b          	slliw	a5,a5,0x8
ffffffffc0200436:	00eaeab3          	or	s5,s5,a4
ffffffffc020043a:	00fb77b3          	and	a5,s6,a5
ffffffffc020043e:	00faeab3          	or	s5,s5,a5
ffffffffc0200442:	2a81                	sext.w	s5,s5
                if (in_memory_node && strcmp(prop_name, "reg") == 0 && prop_len >= 16) {
ffffffffc0200444:	000c9c63          	bnez	s9,ffffffffc020045c <dtb_init+0x23c>
                struct_ptr = (const uint32_t *)(((uintptr_t)struct_ptr + prop_len + 3) & ~3);
ffffffffc0200448:	1a82                	slli	s5,s5,0x20
ffffffffc020044a:	00368793          	addi	a5,a3,3
ffffffffc020044e:	020ada93          	srli	s5,s5,0x20
ffffffffc0200452:	9abe                	add	s5,s5,a5
ffffffffc0200454:	ffcafa93          	andi	s5,s5,-4
        switch (token) {
ffffffffc0200458:	8a56                	mv	s4,s5
ffffffffc020045a:	b5f5                	j	ffffffffc0200346 <dtb_init+0x126>
                uint32_t prop_nameoff = fdt32_to_cpu(*struct_ptr++);
ffffffffc020045c:	008a2783          	lw	a5,8(s4)
                if (in_memory_node && strcmp(prop_name, "reg") == 0 && prop_len >= 16) {
ffffffffc0200460:	85ca                	mv	a1,s2
ffffffffc0200462:	e436                	sd	a3,8(sp)
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200464:	0087d51b          	srliw	a0,a5,0x8
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200468:	0187d61b          	srliw	a2,a5,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020046c:	0187971b          	slliw	a4,a5,0x18
ffffffffc0200470:	0105151b          	slliw	a0,a0,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200474:	0107d79b          	srliw	a5,a5,0x10
ffffffffc0200478:	8f51                	or	a4,a4,a2
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020047a:	01857533          	and	a0,a0,s8
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020047e:	0087979b          	slliw	a5,a5,0x8
ffffffffc0200482:	8d59                	or	a0,a0,a4
ffffffffc0200484:	00fb77b3          	and	a5,s6,a5
ffffffffc0200488:	8d5d                	or	a0,a0,a5
                const char *prop_name = strings_base + prop_nameoff;
ffffffffc020048a:	1502                	slli	a0,a0,0x20
ffffffffc020048c:	9101                	srli	a0,a0,0x20
                if (in_memory_node && strcmp(prop_name, "reg") == 0 && prop_len >= 16) {
ffffffffc020048e:	9522                	add	a0,a0,s0
ffffffffc0200490:	73d000ef          	jal	ra,ffffffffc02013cc <strcmp>
ffffffffc0200494:	66a2                	ld	a3,8(sp)
ffffffffc0200496:	f94d                	bnez	a0,ffffffffc0200448 <dtb_init+0x228>
ffffffffc0200498:	fb59f8e3          	bgeu	s3,s5,ffffffffc0200448 <dtb_init+0x228>
                    *mem_base = fdt64_to_cpu(reg_data[0]);
ffffffffc020049c:	00ca3783          	ld	a5,12(s4)
                    *mem_size = fdt64_to_cpu(reg_data[1]);
ffffffffc02004a0:	014a3703          	ld	a4,20(s4)
        cprintf("Physical Memory from DTB:\n");
ffffffffc02004a4:	00001517          	auipc	a0,0x1
ffffffffc02004a8:	12450513          	addi	a0,a0,292 # ffffffffc02015c8 <etext+0x1a6>
           fdt32_to_cpu(x >> 32);
ffffffffc02004ac:	4207d613          	srai	a2,a5,0x20
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02004b0:	0087d31b          	srliw	t1,a5,0x8
           fdt32_to_cpu(x >> 32);
ffffffffc02004b4:	42075593          	srai	a1,a4,0x20
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02004b8:	0187de1b          	srliw	t3,a5,0x18
ffffffffc02004bc:	0186581b          	srliw	a6,a2,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02004c0:	0187941b          	slliw	s0,a5,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02004c4:	0107d89b          	srliw	a7,a5,0x10
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02004c8:	0187d693          	srli	a3,a5,0x18
ffffffffc02004cc:	01861f1b          	slliw	t5,a2,0x18
ffffffffc02004d0:	0087579b          	srliw	a5,a4,0x8
ffffffffc02004d4:	0103131b          	slliw	t1,t1,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02004d8:	0106561b          	srliw	a2,a2,0x10
ffffffffc02004dc:	010f6f33          	or	t5,t5,a6
ffffffffc02004e0:	0187529b          	srliw	t0,a4,0x18
ffffffffc02004e4:	0185df9b          	srliw	t6,a1,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02004e8:	01837333          	and	t1,t1,s8
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02004ec:	01c46433          	or	s0,s0,t3
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02004f0:	0186f6b3          	and	a3,a3,s8
ffffffffc02004f4:	01859e1b          	slliw	t3,a1,0x18
ffffffffc02004f8:	01871e9b          	slliw	t4,a4,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02004fc:	0107581b          	srliw	a6,a4,0x10
ffffffffc0200500:	0086161b          	slliw	a2,a2,0x8
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200504:	8361                	srli	a4,a4,0x18
ffffffffc0200506:	0107979b          	slliw	a5,a5,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020050a:	0105d59b          	srliw	a1,a1,0x10
ffffffffc020050e:	01e6e6b3          	or	a3,a3,t5
ffffffffc0200512:	00cb7633          	and	a2,s6,a2
ffffffffc0200516:	0088181b          	slliw	a6,a6,0x8
ffffffffc020051a:	0085959b          	slliw	a1,a1,0x8
ffffffffc020051e:	00646433          	or	s0,s0,t1
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200522:	0187f7b3          	and	a5,a5,s8
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200526:	01fe6333          	or	t1,t3,t6
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020052a:	01877c33          	and	s8,a4,s8
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020052e:	0088989b          	slliw	a7,a7,0x8
ffffffffc0200532:	011b78b3          	and	a7,s6,a7
ffffffffc0200536:	005eeeb3          	or	t4,t4,t0
ffffffffc020053a:	00c6e733          	or	a4,a3,a2
ffffffffc020053e:	006c6c33          	or	s8,s8,t1
ffffffffc0200542:	010b76b3          	and	a3,s6,a6
ffffffffc0200546:	00bb7b33          	and	s6,s6,a1
ffffffffc020054a:	01d7e7b3          	or	a5,a5,t4
ffffffffc020054e:	016c6b33          	or	s6,s8,s6
ffffffffc0200552:	01146433          	or	s0,s0,a7
ffffffffc0200556:	8fd5                	or	a5,a5,a3
           fdt32_to_cpu(x >> 32);
ffffffffc0200558:	1702                	slli	a4,a4,0x20
ffffffffc020055a:	1b02                	slli	s6,s6,0x20
    return ((uint64_t)fdt32_to_cpu(x & 0xffffffff) << 32) | 
ffffffffc020055c:	1782                	slli	a5,a5,0x20
           fdt32_to_cpu(x >> 32);
ffffffffc020055e:	9301                	srli	a4,a4,0x20
    return ((uint64_t)fdt32_to_cpu(x & 0xffffffff) << 32) | 
ffffffffc0200560:	1402                	slli	s0,s0,0x20
           fdt32_to_cpu(x >> 32);
ffffffffc0200562:	020b5b13          	srli	s6,s6,0x20
    return ((uint64_t)fdt32_to_cpu(x & 0xffffffff) << 32) | 
ffffffffc0200566:	0167eb33          	or	s6,a5,s6
ffffffffc020056a:	8c59                	or	s0,s0,a4
        cprintf("Physical Memory from DTB:\n");
ffffffffc020056c:	be1ff0ef          	jal	ra,ffffffffc020014c <cprintf>
        cprintf("  Base: 0x%016lx\n", mem_base);
ffffffffc0200570:	85a2                	mv	a1,s0
ffffffffc0200572:	00001517          	auipc	a0,0x1
ffffffffc0200576:	07650513          	addi	a0,a0,118 # ffffffffc02015e8 <etext+0x1c6>
ffffffffc020057a:	bd3ff0ef          	jal	ra,ffffffffc020014c <cprintf>
        cprintf("  Size: 0x%016lx (%ld MB)\n", mem_size, mem_size / (1024 * 1024));
ffffffffc020057e:	014b5613          	srli	a2,s6,0x14
ffffffffc0200582:	85da                	mv	a1,s6
ffffffffc0200584:	00001517          	auipc	a0,0x1
ffffffffc0200588:	07c50513          	addi	a0,a0,124 # ffffffffc0201600 <etext+0x1de>
ffffffffc020058c:	bc1ff0ef          	jal	ra,ffffffffc020014c <cprintf>
        cprintf("  End:  0x%016lx\n", mem_base + mem_size - 1);
ffffffffc0200590:	008b05b3          	add	a1,s6,s0
ffffffffc0200594:	15fd                	addi	a1,a1,-1
ffffffffc0200596:	00001517          	auipc	a0,0x1
ffffffffc020059a:	08a50513          	addi	a0,a0,138 # ffffffffc0201620 <etext+0x1fe>
ffffffffc020059e:	bafff0ef          	jal	ra,ffffffffc020014c <cprintf>
    cprintf("DTB init completed\n");
ffffffffc02005a2:	00001517          	auipc	a0,0x1
ffffffffc02005a6:	0ce50513          	addi	a0,a0,206 # ffffffffc0201670 <etext+0x24e>
        memory_base = mem_base;
ffffffffc02005aa:	00005797          	auipc	a5,0x5
ffffffffc02005ae:	a687bb23          	sd	s0,-1418(a5) # ffffffffc0205020 <memory_base>
        memory_size = mem_size;
ffffffffc02005b2:	00005797          	auipc	a5,0x5
ffffffffc02005b6:	a767bb23          	sd	s6,-1418(a5) # ffffffffc0205028 <memory_size>
    cprintf("DTB init completed\n");
ffffffffc02005ba:	b3f5                	j	ffffffffc02003a6 <dtb_init+0x186>

ffffffffc02005bc <get_memory_base>:

uint64_t get_memory_base(void) {
    return memory_base;
}
ffffffffc02005bc:	00005517          	auipc	a0,0x5
ffffffffc02005c0:	a6453503          	ld	a0,-1436(a0) # ffffffffc0205020 <memory_base>
ffffffffc02005c4:	8082                	ret

ffffffffc02005c6 <get_memory_size>:

uint64_t get_memory_size(void) {
    return memory_size;
ffffffffc02005c6:	00005517          	auipc	a0,0x5
ffffffffc02005ca:	a6253503          	ld	a0,-1438(a0) # ffffffffc0205028 <memory_size>
ffffffffc02005ce:	8082                	ret

ffffffffc02005d0 <buddy_init>:
    }
    return k;
}

static void buddy_init(void) {
    if (free_list!=NULL) {
ffffffffc02005d0:	00005797          	auipc	a5,0x5
ffffffffc02005d4:	a687b783          	ld	a5,-1432(a5) # ffffffffc0205038 <free_list>
ffffffffc02005d8:	c385                	beqz	a5,ffffffffc02005f8 <buddy_init+0x28>
        for (int i = 0; i <= max_order; i++) {
ffffffffc02005da:	00005717          	auipc	a4,0x5
ffffffffc02005de:	a6672703          	lw	a4,-1434(a4) # ffffffffc0205040 <max_order>
ffffffffc02005e2:	00074b63          	bltz	a4,ffffffffc02005f8 <buddy_init+0x28>
ffffffffc02005e6:	0712                	slli	a4,a4,0x4
ffffffffc02005e8:	01078693          	addi	a3,a5,16
ffffffffc02005ec:	9736                	add	a4,a4,a3
 * list_init - initialize a new entry
 * @elm:        new entry to be initialized
 * */
static inline void
list_init(list_entry_t *elm) {
    elm->prev = elm->next = elm;
ffffffffc02005ee:	e79c                	sd	a5,8(a5)
ffffffffc02005f0:	e39c                	sd	a5,0(a5)
ffffffffc02005f2:	07c1                	addi	a5,a5,16
ffffffffc02005f4:	fee79de3          	bne	a5,a4,ffffffffc02005ee <buddy_init+0x1e>
            list_init(&free_list[i]); // list.h中定义，初始化链表
        }
    }
    buddy_nr_free = 0;
ffffffffc02005f8:	00005797          	auipc	a5,0x5
ffffffffc02005fc:	a207bc23          	sd	zero,-1480(a5) # ffffffffc0205030 <buddy_nr_free>
}
ffffffffc0200600:	8082                	ret

ffffffffc0200602 <buddy_alloc_pages>:
    }
}

static struct Page *buddy_alloc_pages(size_t n) {
    // 分配
    if(n==0||n>buddy_nr_free){
ffffffffc0200602:	c579                	beqz	a0,ffffffffc02006d0 <buddy_alloc_pages+0xce>
ffffffffc0200604:	00005f17          	auipc	t5,0x5
ffffffffc0200608:	a2cf0f13          	addi	t5,t5,-1492 # ffffffffc0205030 <buddy_nr_free>
ffffffffc020060c:	000f3303          	ld	t1,0(t5)
ffffffffc0200610:	0ca36063          	bltu	t1,a0,ffffffffc02006d0 <buddy_alloc_pages+0xce>
    while (s < n) { 
ffffffffc0200614:	4785                	li	a5,1
        return NULL;
    }
    int or=cal_buddy_order(n),order=or;
    struct Page *tar=NULL;
    for(int i=or;i<=max_order;i++){
ffffffffc0200616:	00005597          	auipc	a1,0x5
ffffffffc020061a:	a2a5a583          	lw	a1,-1494(a1) # ffffffffc0205040 <max_order>
    int k = 0;
ffffffffc020061e:	4601                	li	a2,0
    while (s < n) { 
ffffffffc0200620:	0af50663          	beq	a0,a5,ffffffffc02006cc <buddy_alloc_pages+0xca>
        s *= 2; 
ffffffffc0200624:	0786                	slli	a5,a5,0x1
        k++; 
ffffffffc0200626:	2605                	addiw	a2,a2,1
    while (s < n) { 
ffffffffc0200628:	fea7eee3          	bltu	a5,a0,ffffffffc0200624 <buddy_alloc_pages+0x22>
    for(int i=or;i<=max_order;i++){
ffffffffc020062c:	0ac5c263          	blt	a1,a2,ffffffffc02006d0 <buddy_alloc_pages+0xce>
        if(list_empty(&free_list[i])==0){
ffffffffc0200630:	00005697          	auipc	a3,0x5
ffffffffc0200634:	a086b683          	ld	a3,-1528(a3) # ffffffffc0205038 <free_list>
ffffffffc0200638:	00461713          	slli	a4,a2,0x4
ffffffffc020063c:	9736                	add	a4,a4,a3
ffffffffc020063e:	87b2                	mv	a5,a2
ffffffffc0200640:	a029                	j	ffffffffc020064a <buddy_alloc_pages+0x48>
    for(int i=or;i<=max_order;i++){
ffffffffc0200642:	2785                	addiw	a5,a5,1
ffffffffc0200644:	0741                	addi	a4,a4,16
ffffffffc0200646:	08f5c563          	blt	a1,a5,ffffffffc02006d0 <buddy_alloc_pages+0xce>
 * list_empty - tests whether a list is empty
 * @list:       the list to test.
 * */
static inline bool
list_empty(list_entry_t *list) {
    return list->next == list;
ffffffffc020064a:	00873883          	ld	a7,8(a4)
        if(list_empty(&free_list[i])==0){
ffffffffc020064e:	fee88ae3          	beq	a7,a4,ffffffffc0200642 <buddy_alloc_pages+0x40>
    __list_del(listelm->prev, listelm->next);
ffffffffc0200652:	0008b503          	ld	a0,0(a7)
ffffffffc0200656:	0088b583          	ld	a1,8(a7)
            list_entry_t *first = list_next(&free_list[i]);
            tar = le2page(first, page_link);
            list_del(&tar->page_link);
            buddy_nr_free -= (1UL << i);
ffffffffc020065a:	4705                	li	a4,1
ffffffffc020065c:	00f71733          	sll	a4,a4,a5
 * This is only for internal list manipulation where we know
 * the prev/next entries already!
 * */
static inline void
__list_del(list_entry_t *prev, list_entry_t *next) {
    prev->next = next;
ffffffffc0200660:	e50c                	sd	a1,8(a0)
ffffffffc0200662:	40e30333          	sub	t1,t1,a4
    next->prev = prev;
ffffffffc0200666:	e188                	sd	a0,0(a1)
ffffffffc0200668:	006f3023          	sd	t1,0(t5)
            or=i;
            break;
        }
    }
    for(int i=or-1;i>=order;i--){
ffffffffc020066c:	37fd                	addiw	a5,a5,-1
            tar = le2page(first, page_link);
ffffffffc020066e:	fe888513          	addi	a0,a7,-24
    for(int i=or-1;i>=order;i--){
ffffffffc0200672:	04c7c563          	blt	a5,a2,ffffffffc02006bc <buddy_alloc_pages+0xba>
ffffffffc0200676:	00479713          	slli	a4,a5,0x4
ffffffffc020067a:	96ba                	add	a3,a3,a4
ffffffffc020067c:	fff6059b          	addiw	a1,a2,-1
        size_t half=1UL<<i;
        struct Page*right=tar+half;
ffffffffc0200680:	02800e93          	li	t4,40
        size_t half=1UL<<i;
ffffffffc0200684:	4e05                	li	t3,1
        struct Page*right=tar+half;
ffffffffc0200686:	00fe9733          	sll	a4,t4,a5
ffffffffc020068a:	972a                	add	a4,a4,a0
        SetPageProperty(right);
ffffffffc020068c:	6710                	ld	a2,8(a4)
    __list_add(elm, listelm, listelm->next);
ffffffffc020068e:	0086b803          	ld	a6,8(a3)
        right->property=i;
ffffffffc0200692:	cb1c                	sw	a5,16(a4)
        SetPageProperty(right);
ffffffffc0200694:	00266613          	ori	a2,a2,2
ffffffffc0200698:	e710                	sd	a2,8(a4)
        list_add(&free_list[i], &right->page_link);
ffffffffc020069a:	01870613          	addi	a2,a4,24
    prev->next = next->prev = elm;
ffffffffc020069e:	00c83023          	sd	a2,0(a6)
ffffffffc02006a2:	e690                	sd	a2,8(a3)
    elm->prev = prev;
ffffffffc02006a4:	ef14                	sd	a3,24(a4)
        size_t half=1UL<<i;
ffffffffc02006a6:	00fe1633          	sll	a2,t3,a5
    elm->next = next;
ffffffffc02006aa:	03073023          	sd	a6,32(a4)
    for(int i=or-1;i>=order;i--){
ffffffffc02006ae:	37fd                	addiw	a5,a5,-1
        buddy_nr_free += half;
ffffffffc02006b0:	9332                	add	t1,t1,a2
    for(int i=or-1;i>=order;i--){
ffffffffc02006b2:	16c1                	addi	a3,a3,-16
ffffffffc02006b4:	fcb799e3          	bne	a5,a1,ffffffffc0200686 <buddy_alloc_pages+0x84>
ffffffffc02006b8:	006f3023          	sd	t1,0(t5)
    }
    if (tar == NULL){
        return NULL;
    }
    ClearPageProperty(tar);
ffffffffc02006bc:	ff08b783          	ld	a5,-16(a7)
    tar->property = 0;
ffffffffc02006c0:	fe08ac23          	sw	zero,-8(a7)
    ClearPageProperty(tar);
ffffffffc02006c4:	9bf5                	andi	a5,a5,-3
ffffffffc02006c6:	fef8b823          	sd	a5,-16(a7)
    return tar;
ffffffffc02006ca:	8082                	ret
    for(int i=or;i<=max_order;i++){
ffffffffc02006cc:	f605d2e3          	bgez	a1,ffffffffc0200630 <buddy_alloc_pages+0x2e>
        return NULL;
ffffffffc02006d0:	4501                	li	a0,0
}
ffffffffc02006d2:	8082                	ret

ffffffffc02006d4 <buddy_nr_free_pages>:
}


static size_t buddy_nr_free_pages(void) { // 得到可用于分配的空闲页总数
    return buddy_nr_free;
}
ffffffffc02006d4:	00005517          	auipc	a0,0x5
ffffffffc02006d8:	95c53503          	ld	a0,-1700(a0) # ffffffffc0205030 <buddy_nr_free>
ffffffffc02006dc:	8082                	ret

ffffffffc02006de <basic_check>:

static void basic_check(void) {
ffffffffc02006de:	1141                	addi	sp,sp,-16
ffffffffc02006e0:	e406                	sd	ra,8(sp)
    // 基础检查
    assert(free_list != NULL);
ffffffffc02006e2:	00005817          	auipc	a6,0x5
ffffffffc02006e6:	95683803          	ld	a6,-1706(a6) # ffffffffc0205038 <free_list>
ffffffffc02006ea:	12080b63          	beqz	a6,ffffffffc0200820 <basic_check+0x142>
    assert(max_order >= 0);
ffffffffc02006ee:	00005f97          	auipc	t6,0x5
ffffffffc02006f2:	952faf83          	lw	t6,-1710(t6) # ffffffffc0205040 <max_order>
ffffffffc02006f6:	100fc563          	bltz	t6,ffffffffc0200800 <basic_check+0x122>
extern struct Page *pages;
extern size_t npage;
extern const size_t nbase;
extern uint64_t va_pa_offset;

static inline ppn_t page2ppn(struct Page *page) { return page - pages + nbase; }
ffffffffc02006fa:	00005f17          	auipc	t5,0x5
ffffffffc02006fe:	956f3f03          	ld	t5,-1706(t5) # ffffffffc0205050 <pages>
ffffffffc0200702:	00001e97          	auipc	t4,0x1
ffffffffc0200706:	586ebe83          	ld	t4,1414(t4) # ffffffffc0201c88 <nbase>
        for(;le!=head;){
            struct Page*p=le2page(le, page_link);
            assert(PageProperty(p));
            assert((int)p->property==i);
            ppn_t idx=page2ppn(p);
            assert(idx < npage);
ffffffffc020070a:	00005e17          	auipc	t3,0x5
ffffffffc020070e:	93ee3e03          	ld	t3,-1730(t3) # ffffffffc0205048 <npage>
    for(int i=0;i<=max_order;i++){
ffffffffc0200712:	4581                	li	a1,0
    size_t sum = 0;
ffffffffc0200714:	4601                	li	a2,0
            assert((idx & ((1UL<<i)-1))==0);
ffffffffc0200716:	4385                	li	t2,1
ffffffffc0200718:	52fd                	li	t0,-1
ffffffffc020071a:	00001317          	auipc	t1,0x1
ffffffffc020071e:	56633303          	ld	t1,1382(t1) # ffffffffc0201c80 <error_string+0x38>
    return listelm->next;
ffffffffc0200722:	00883703          	ld	a4,8(a6)
        for(;le!=head;){
ffffffffc0200726:	04e80063          	beq	a6,a4,ffffffffc0200766 <basic_check+0x88>
ffffffffc020072a:	00b29533          	sll	a0,t0,a1
            assert((idx & ((1UL<<i)-1))==0);
ffffffffc020072e:	00b398b3          	sll	a7,t2,a1
ffffffffc0200732:	fff54513          	not	a0,a0
            assert(PageProperty(p));
ffffffffc0200736:	ff073683          	ld	a3,-16(a4)
            struct Page*p=le2page(le, page_link);
ffffffffc020073a:	fe870793          	addi	a5,a4,-24
            assert(PageProperty(p));
ffffffffc020073e:	8a89                	andi	a3,a3,2
ffffffffc0200740:	c2a5                	beqz	a3,ffffffffc02007a0 <basic_check+0xc2>
            assert((int)p->property==i);
ffffffffc0200742:	ff872683          	lw	a3,-8(a4)
ffffffffc0200746:	06b69d63          	bne	a3,a1,ffffffffc02007c0 <basic_check+0xe2>
ffffffffc020074a:	41e787b3          	sub	a5,a5,t5
ffffffffc020074e:	878d                	srai	a5,a5,0x3
ffffffffc0200750:	026787b3          	mul	a5,a5,t1
ffffffffc0200754:	97f6                	add	a5,a5,t4
            assert(idx < npage);
ffffffffc0200756:	09c7f563          	bgeu	a5,t3,ffffffffc02007e0 <basic_check+0x102>
            assert((idx & ((1UL<<i)-1))==0);
ffffffffc020075a:	8fe9                	and	a5,a5,a0
ffffffffc020075c:	e395                	bnez	a5,ffffffffc0200780 <basic_check+0xa2>
ffffffffc020075e:	6718                	ld	a4,8(a4)
            sum += (1UL << i);
ffffffffc0200760:	9646                	add	a2,a2,a7
        for(;le!=head;){
ffffffffc0200762:	fd071ae3          	bne	a4,a6,ffffffffc0200736 <basic_check+0x58>
    for(int i=0;i<=max_order;i++){
ffffffffc0200766:	2585                	addiw	a1,a1,1
ffffffffc0200768:	0841                	addi	a6,a6,16
ffffffffc020076a:	fabfdce3          	bge	t6,a1,ffffffffc0200722 <basic_check+0x44>
            le=list_next(le);
        }
    }
    assert(sum == buddy_nr_free);
ffffffffc020076e:	00005797          	auipc	a5,0x5
ffffffffc0200772:	8c27b783          	ld	a5,-1854(a5) # ffffffffc0205030 <buddy_nr_free>
ffffffffc0200776:	0cc79563          	bne	a5,a2,ffffffffc0200840 <basic_check+0x162>
}
ffffffffc020077a:	60a2                	ld	ra,8(sp)
ffffffffc020077c:	0141                	addi	sp,sp,16
ffffffffc020077e:	8082                	ret
            assert((idx & ((1UL<<i)-1))==0);
ffffffffc0200780:	00001697          	auipc	a3,0x1
ffffffffc0200784:	fa068693          	addi	a3,a3,-96 # ffffffffc0201720 <etext+0x2fe>
ffffffffc0200788:	00001617          	auipc	a2,0x1
ffffffffc020078c:	f1860613          	addi	a2,a2,-232 # ffffffffc02016a0 <etext+0x27e>
ffffffffc0200790:	0c600593          	li	a1,198
ffffffffc0200794:	00001517          	auipc	a0,0x1
ffffffffc0200798:	f2450513          	addi	a0,a0,-220 # ffffffffc02016b8 <etext+0x296>
ffffffffc020079c:	a27ff0ef          	jal	ra,ffffffffc02001c2 <__panic>
            assert(PageProperty(p));
ffffffffc02007a0:	00001697          	auipc	a3,0x1
ffffffffc02007a4:	f4868693          	addi	a3,a3,-184 # ffffffffc02016e8 <etext+0x2c6>
ffffffffc02007a8:	00001617          	auipc	a2,0x1
ffffffffc02007ac:	ef860613          	addi	a2,a2,-264 # ffffffffc02016a0 <etext+0x27e>
ffffffffc02007b0:	0c200593          	li	a1,194
ffffffffc02007b4:	00001517          	auipc	a0,0x1
ffffffffc02007b8:	f0450513          	addi	a0,a0,-252 # ffffffffc02016b8 <etext+0x296>
ffffffffc02007bc:	a07ff0ef          	jal	ra,ffffffffc02001c2 <__panic>
            assert((int)p->property==i);
ffffffffc02007c0:	00001697          	auipc	a3,0x1
ffffffffc02007c4:	f3868693          	addi	a3,a3,-200 # ffffffffc02016f8 <etext+0x2d6>
ffffffffc02007c8:	00001617          	auipc	a2,0x1
ffffffffc02007cc:	ed860613          	addi	a2,a2,-296 # ffffffffc02016a0 <etext+0x27e>
ffffffffc02007d0:	0c300593          	li	a1,195
ffffffffc02007d4:	00001517          	auipc	a0,0x1
ffffffffc02007d8:	ee450513          	addi	a0,a0,-284 # ffffffffc02016b8 <etext+0x296>
ffffffffc02007dc:	9e7ff0ef          	jal	ra,ffffffffc02001c2 <__panic>
            assert(idx < npage);
ffffffffc02007e0:	00001697          	auipc	a3,0x1
ffffffffc02007e4:	f3068693          	addi	a3,a3,-208 # ffffffffc0201710 <etext+0x2ee>
ffffffffc02007e8:	00001617          	auipc	a2,0x1
ffffffffc02007ec:	eb860613          	addi	a2,a2,-328 # ffffffffc02016a0 <etext+0x27e>
ffffffffc02007f0:	0c500593          	li	a1,197
ffffffffc02007f4:	00001517          	auipc	a0,0x1
ffffffffc02007f8:	ec450513          	addi	a0,a0,-316 # ffffffffc02016b8 <etext+0x296>
ffffffffc02007fc:	9c7ff0ef          	jal	ra,ffffffffc02001c2 <__panic>
    assert(max_order >= 0);
ffffffffc0200800:	00001697          	auipc	a3,0x1
ffffffffc0200804:	ed868693          	addi	a3,a3,-296 # ffffffffc02016d8 <etext+0x2b6>
ffffffffc0200808:	00001617          	auipc	a2,0x1
ffffffffc020080c:	e9860613          	addi	a2,a2,-360 # ffffffffc02016a0 <etext+0x27e>
ffffffffc0200810:	0bb00593          	li	a1,187
ffffffffc0200814:	00001517          	auipc	a0,0x1
ffffffffc0200818:	ea450513          	addi	a0,a0,-348 # ffffffffc02016b8 <etext+0x296>
ffffffffc020081c:	9a7ff0ef          	jal	ra,ffffffffc02001c2 <__panic>
    assert(free_list != NULL);
ffffffffc0200820:	00001697          	auipc	a3,0x1
ffffffffc0200824:	e6868693          	addi	a3,a3,-408 # ffffffffc0201688 <etext+0x266>
ffffffffc0200828:	00001617          	auipc	a2,0x1
ffffffffc020082c:	e7860613          	addi	a2,a2,-392 # ffffffffc02016a0 <etext+0x27e>
ffffffffc0200830:	0ba00593          	li	a1,186
ffffffffc0200834:	00001517          	auipc	a0,0x1
ffffffffc0200838:	e8450513          	addi	a0,a0,-380 # ffffffffc02016b8 <etext+0x296>
ffffffffc020083c:	987ff0ef          	jal	ra,ffffffffc02001c2 <__panic>
    assert(sum == buddy_nr_free);
ffffffffc0200840:	00001697          	auipc	a3,0x1
ffffffffc0200844:	ef868693          	addi	a3,a3,-264 # ffffffffc0201738 <etext+0x316>
ffffffffc0200848:	00001617          	auipc	a2,0x1
ffffffffc020084c:	e5860613          	addi	a2,a2,-424 # ffffffffc02016a0 <etext+0x27e>
ffffffffc0200850:	0cb00593          	li	a1,203
ffffffffc0200854:	00001517          	auipc	a0,0x1
ffffffffc0200858:	e6450513          	addi	a0,a0,-412 # ffffffffc02016b8 <etext+0x296>
ffffffffc020085c:	967ff0ef          	jal	ra,ffffffffc02001c2 <__panic>

ffffffffc0200860 <buddy_free_pages.part.0>:
buddy_free_pages(struct Page *base, size_t n) {
ffffffffc0200860:	1141                	addi	sp,sp,-16
ffffffffc0200862:	e406                	sd	ra,8(sp)
    while (s < n) { 
ffffffffc0200864:	4785                	li	a5,1
ffffffffc0200866:	14b7f563          	bgeu	a5,a1,ffffffffc02009b0 <buddy_free_pages.part.0+0x150>
    int k = 0;
ffffffffc020086a:	4681                	li	a3,0
        s *= 2; 
ffffffffc020086c:	0786                	slli	a5,a5,0x1
        k++; 
ffffffffc020086e:	2685                	addiw	a3,a3,1
    while (s < n) { 
ffffffffc0200870:	feb7eee3          	bltu	a5,a1,ffffffffc020086c <buddy_free_pages.part.0+0xc>
    size_t block_size = (1 << order);  // 实际要释放的页数
ffffffffc0200874:	4605                	li	a2,1
ffffffffc0200876:	00d6163b          	sllw	a2,a2,a3
    for (; p != base + block_size; p++) {
ffffffffc020087a:	00261593          	slli	a1,a2,0x2
ffffffffc020087e:	95b2                	add	a1,a1,a2
ffffffffc0200880:	058e                	slli	a1,a1,0x3
ffffffffc0200882:	95aa                	add	a1,a1,a0
ffffffffc0200884:	00b50f63          	beq	a0,a1,ffffffffc02008a2 <buddy_free_pages.part.0+0x42>
ffffffffc0200888:	87aa                	mv	a5,a0
        assert(!PageReserved(p) && !PageProperty(p));
ffffffffc020088a:	6798                	ld	a4,8(a5)
ffffffffc020088c:	8b0d                	andi	a4,a4,3
ffffffffc020088e:	12071663          	bnez	a4,ffffffffc02009ba <buddy_free_pages.part.0+0x15a>
        p->flags = 0;
ffffffffc0200892:	0007b423          	sd	zero,8(a5)



static inline int page_ref(struct Page *page) { return page->ref; }

static inline void set_page_ref(struct Page *page, int val) { page->ref = val; }
ffffffffc0200896:	0007a023          	sw	zero,0(a5)
    for (; p != base + block_size; p++) {
ffffffffc020089a:	02878793          	addi	a5,a5,40
ffffffffc020089e:	feb796e3          	bne	a5,a1,ffffffffc020088a <buddy_free_pages.part.0+0x2a>
static inline ppn_t page2ppn(struct Page *page) { return page - pages + nbase; }
ffffffffc02008a2:	00004317          	auipc	t1,0x4
ffffffffc02008a6:	7ae33303          	ld	t1,1966(t1) # ffffffffc0205050 <pages>
ffffffffc02008aa:	40650e33          	sub	t3,a0,t1
ffffffffc02008ae:	403e5713          	srai	a4,t3,0x3
ffffffffc02008b2:	00001e97          	auipc	t4,0x1
ffffffffc02008b6:	3ceebe83          	ld	t4,974(t4) # ffffffffc0201c80 <error_string+0x38>
ffffffffc02008ba:	03d70733          	mul	a4,a4,t4
ffffffffc02008be:	00001897          	auipc	a7,0x1
ffffffffc02008c2:	3ca8b883          	ld	a7,970(a7) # ffffffffc0201c88 <nbase>
    assert((base_addr & ((block_size << PGSHIFT) - 1)) == 0); 
ffffffffc02008c6:	00c61793          	slli	a5,a2,0xc
ffffffffc02008ca:	fff78593          	addi	a1,a5,-1
ffffffffc02008ce:	9746                	add	a4,a4,a7
    return page2ppn(page) << PGSHIFT;
ffffffffc02008d0:	0732                	slli	a4,a4,0xc
ffffffffc02008d2:	8df9                	and	a1,a1,a4
ffffffffc02008d4:	10059f63          	bnez	a1,ffffffffc02009f2 <buddy_free_pages.part.0+0x192>
    buddy_nr_free += block_size;
ffffffffc02008d8:	00004f17          	auipc	t5,0x4
ffffffffc02008dc:	758f0f13          	addi	t5,t5,1880 # ffffffffc0205030 <buddy_nr_free>
ffffffffc02008e0:	000f3803          	ld	a6,0(t5)
    SetPageProperty(base);
ffffffffc02008e4:	650c                	ld	a1,8(a0)
    base->property = order;
ffffffffc02008e6:	00068f9b          	sext.w	t6,a3
    buddy_nr_free += block_size;
ffffffffc02008ea:	9832                	add	a6,a6,a2
    SetPageProperty(base);
ffffffffc02008ec:	0025e593          	ori	a1,a1,2
    buddy_nr_free += block_size;
ffffffffc02008f0:	010f3023          	sd	a6,0(t5)
    base->property = order;
ffffffffc02008f4:	01f52823          	sw	t6,16(a0)
    SetPageProperty(base);
ffffffffc02008f8:	e50c                	sd	a1,8(a0)
    while (order < max_order) {
ffffffffc02008fa:	00004f17          	auipc	t5,0x4
ffffffffc02008fe:	746f2f03          	lw	t5,1862(t5) # ffffffffc0205040 <max_order>
ffffffffc0200902:	07e6db63          	bge	a3,t5,ffffffffc0200978 <buddy_free_pages.part.0+0x118>
static inline int page_ref_dec(struct Page *page) {
    page->ref -= 1;
    return page->ref;
}
static inline struct Page *pa2page(uintptr_t pa) {
    if (PPN(pa) >= npage) {
ffffffffc0200906:	00004297          	auipc	t0,0x4
ffffffffc020090a:	7422b283          	ld	t0,1858(t0) # ffffffffc0205048 <npage>
        if (PageReserved(buddy) || !PageProperty(buddy))
ffffffffc020090e:	4f89                	li	t6,2
ffffffffc0200910:	a83d                	j	ffffffffc020094e <buddy_free_pages.part.0+0xee>
        if ((int)buddy->property != order)
ffffffffc0200912:	4b8c                	lw	a1,16(a5)
ffffffffc0200914:	04d59d63          	bne	a1,a3,ffffffffc020096e <buddy_free_pages.part.0+0x10e>
    __list_del(listelm->prev, listelm->next);
ffffffffc0200918:	0187b803          	ld	a6,24(a5)
ffffffffc020091c:	738c                	ld	a1,32(a5)
        ClearPageProperty(buddy);
ffffffffc020091e:	9b75                	andi	a4,a4,-3
    prev->next = next;
ffffffffc0200920:	00b83423          	sd	a1,8(a6)
    next->prev = prev;
ffffffffc0200924:	0105b023          	sd	a6,0(a1)
ffffffffc0200928:	e798                	sd	a4,8(a5)
        if (buddy < base)
ffffffffc020092a:	00a7f563          	bgeu	a5,a0,ffffffffc0200934 <buddy_free_pages.part.0+0xd4>
ffffffffc020092e:	853e                	mv	a0,a5
ffffffffc0200930:	40678e33          	sub	t3,a5,t1
static inline ppn_t page2ppn(struct Page *page) { return page - pages + nbase; }
ffffffffc0200934:	403e5793          	srai	a5,t3,0x3
ffffffffc0200938:	03d787b3          	mul	a5,a5,t4
        order++;
ffffffffc020093c:	2685                	addiw	a3,a3,1
        block_size <<= 1;
ffffffffc020093e:	0606                	slli	a2,a2,0x1
ffffffffc0200940:	97c6                	add	a5,a5,a7
    return page2ppn(page) << PGSHIFT;
ffffffffc0200942:	00c79713          	slli	a4,a5,0xc
    while (order < max_order) {
ffffffffc0200946:	03e68463          	beq	a3,t5,ffffffffc020096e <buddy_free_pages.part.0+0x10e>
ffffffffc020094a:	00c61793          	slli	a5,a2,0xc
        uintptr_t buddy_addr = base_addr ^ (block_size << PGSHIFT);  // 找到伙伴物理地址
ffffffffc020094e:	8fb9                	xor	a5,a5,a4
    if (PPN(pa) >= npage) {
ffffffffc0200950:	83b1                	srli	a5,a5,0xc
ffffffffc0200952:	0857f463          	bgeu	a5,t0,ffffffffc02009da <buddy_free_pages.part.0+0x17a>
        panic("pa2page called with invalid pa");
    }
    return &pages[PPN(pa) - nbase];
ffffffffc0200956:	41178733          	sub	a4,a5,a7
ffffffffc020095a:	00271793          	slli	a5,a4,0x2
ffffffffc020095e:	97ba                	add	a5,a5,a4
ffffffffc0200960:	078e                	slli	a5,a5,0x3
ffffffffc0200962:	979a                	add	a5,a5,t1
        if (PageReserved(buddy) || !PageProperty(buddy))
ffffffffc0200964:	6798                	ld	a4,8(a5)
ffffffffc0200966:	00377593          	andi	a1,a4,3
ffffffffc020096a:	fbf584e3          	beq	a1,t6,ffffffffc0200912 <buddy_free_pages.part.0+0xb2>
    SetPageProperty(base);
ffffffffc020096e:	650c                	ld	a1,8(a0)
    base->property = order;
ffffffffc0200970:	00068f9b          	sext.w	t6,a3
    SetPageProperty(base);
ffffffffc0200974:	0025e593          	ori	a1,a1,2
    list_entry_t *le = &free_list[order];
ffffffffc0200978:	00004797          	auipc	a5,0x4
ffffffffc020097c:	6c07b783          	ld	a5,1728(a5) # ffffffffc0205038 <free_list>
ffffffffc0200980:	0692                	slli	a3,a3,0x4
ffffffffc0200982:	96be                	add	a3,a3,a5
ffffffffc0200984:	87b6                	mv	a5,a3
    while ((le = list_next(le)) != &free_list[order]) {
ffffffffc0200986:	a029                	j	ffffffffc0200990 <buddy_free_pages.part.0+0x130>
        struct Page *page = le2page(le, page_link);
ffffffffc0200988:	fe878713          	addi	a4,a5,-24
        if (page > base) break;
ffffffffc020098c:	00e56563          	bltu	a0,a4,ffffffffc0200996 <buddy_free_pages.part.0+0x136>
    return listelm->next;
ffffffffc0200990:	679c                	ld	a5,8(a5)
    while ((le = list_next(le)) != &free_list[order]) {
ffffffffc0200992:	fef69be3          	bne	a3,a5,ffffffffc0200988 <buddy_free_pages.part.0+0x128>
    __list_add(elm, listelm->prev, listelm);
ffffffffc0200996:	6398                	ld	a4,0(a5)
    list_add_before(le, &(base->page_link));
ffffffffc0200998:	01850693          	addi	a3,a0,24
    prev->next = next->prev = elm;
ffffffffc020099c:	e394                	sd	a3,0(a5)
}
ffffffffc020099e:	60a2                	ld	ra,8(sp)
ffffffffc02009a0:	e714                	sd	a3,8(a4)
    elm->next = next;
ffffffffc02009a2:	f11c                	sd	a5,32(a0)
    elm->prev = prev;
ffffffffc02009a4:	ed18                	sd	a4,24(a0)
    base->property = order;
ffffffffc02009a6:	01f52823          	sw	t6,16(a0)
    SetPageProperty(base);
ffffffffc02009aa:	e50c                	sd	a1,8(a0)
}
ffffffffc02009ac:	0141                	addi	sp,sp,16
ffffffffc02009ae:	8082                	ret
    while (s < n) { 
ffffffffc02009b0:	4605                	li	a2,1
    int k = 0;
ffffffffc02009b2:	4681                	li	a3,0
ffffffffc02009b4:	02850593          	addi	a1,a0,40
ffffffffc02009b8:	bdc1                	j	ffffffffc0200888 <buddy_free_pages.part.0+0x28>
        assert(!PageReserved(p) && !PageProperty(p));
ffffffffc02009ba:	00001697          	auipc	a3,0x1
ffffffffc02009be:	d9668693          	addi	a3,a3,-618 # ffffffffc0201750 <etext+0x32e>
ffffffffc02009c2:	00001617          	auipc	a2,0x1
ffffffffc02009c6:	cde60613          	addi	a2,a2,-802 # ffffffffc02016a0 <etext+0x27e>
ffffffffc02009ca:	07d00593          	li	a1,125
ffffffffc02009ce:	00001517          	auipc	a0,0x1
ffffffffc02009d2:	cea50513          	addi	a0,a0,-790 # ffffffffc02016b8 <etext+0x296>
ffffffffc02009d6:	fecff0ef          	jal	ra,ffffffffc02001c2 <__panic>
        panic("pa2page called with invalid pa");
ffffffffc02009da:	00001617          	auipc	a2,0x1
ffffffffc02009de:	dd660613          	addi	a2,a2,-554 # ffffffffc02017b0 <etext+0x38e>
ffffffffc02009e2:	06a00593          	li	a1,106
ffffffffc02009e6:	00001517          	auipc	a0,0x1
ffffffffc02009ea:	dea50513          	addi	a0,a0,-534 # ffffffffc02017d0 <etext+0x3ae>
ffffffffc02009ee:	fd4ff0ef          	jal	ra,ffffffffc02001c2 <__panic>
    assert((base_addr & ((block_size << PGSHIFT) - 1)) == 0); 
ffffffffc02009f2:	00001697          	auipc	a3,0x1
ffffffffc02009f6:	d8668693          	addi	a3,a3,-634 # ffffffffc0201778 <etext+0x356>
ffffffffc02009fa:	00001617          	auipc	a2,0x1
ffffffffc02009fe:	ca660613          	addi	a2,a2,-858 # ffffffffc02016a0 <etext+0x27e>
ffffffffc0200a02:	08400593          	li	a1,132
ffffffffc0200a06:	00001517          	auipc	a0,0x1
ffffffffc0200a0a:	cb250513          	addi	a0,a0,-846 # ffffffffc02016b8 <etext+0x296>
ffffffffc0200a0e:	fb4ff0ef          	jal	ra,ffffffffc02001c2 <__panic>

ffffffffc0200a12 <buddy_free_pages>:
    assert(n > 0);
ffffffffc0200a12:	c191                	beqz	a1,ffffffffc0200a16 <buddy_free_pages+0x4>
ffffffffc0200a14:	b5b1                	j	ffffffffc0200860 <buddy_free_pages.part.0>
buddy_free_pages(struct Page *base, size_t n) {
ffffffffc0200a16:	1141                	addi	sp,sp,-16
    assert(n > 0);
ffffffffc0200a18:	00001697          	auipc	a3,0x1
ffffffffc0200a1c:	dc868693          	addi	a3,a3,-568 # ffffffffc02017e0 <etext+0x3be>
ffffffffc0200a20:	00001617          	auipc	a2,0x1
ffffffffc0200a24:	c8060613          	addi	a2,a2,-896 # ffffffffc02016a0 <etext+0x27e>
ffffffffc0200a28:	07400593          	li	a1,116
ffffffffc0200a2c:	00001517          	auipc	a0,0x1
ffffffffc0200a30:	c8c50513          	addi	a0,a0,-884 # ffffffffc02016b8 <etext+0x296>
buddy_free_pages(struct Page *base, size_t n) {
ffffffffc0200a34:	e406                	sd	ra,8(sp)
    assert(n > 0);
ffffffffc0200a36:	f8cff0ef          	jal	ra,ffffffffc02001c2 <__panic>

ffffffffc0200a3a <buddy_init_memmap>:
    while ((1UL << (i + 1)) <= n) {
ffffffffc0200a3a:	4705                	li	a4,1
ffffffffc0200a3c:	4785                	li	a5,1
ffffffffc0200a3e:	4685                	li	a3,1
ffffffffc0200a40:	18b77d63          	bgeu	a4,a1,ffffffffc0200bda <buddy_init_memmap+0x1a0>
ffffffffc0200a44:	863e                	mv	a2,a5
ffffffffc0200a46:	2785                	addiw	a5,a5,1
ffffffffc0200a48:	00f69733          	sll	a4,a3,a5
ffffffffc0200a4c:	fee5fce3          	bgeu	a1,a4,ffffffffc0200a44 <buddy_init_memmap+0xa>
    size_t header_size = (max_order + 1) * sizeof(list_entry_t);
ffffffffc0200a50:	00479693          	slli	a3,a5,0x4
    size_t header_pages_num = (header_size + PGSIZE - 1) / PGSIZE;
ffffffffc0200a54:	6785                	lui	a5,0x1
ffffffffc0200a56:	17fd                	addi	a5,a5,-1
ffffffffc0200a58:	96be                	add	a3,a3,a5
ffffffffc0200a5a:	82b1                	srli	a3,a3,0xc
ffffffffc0200a5c:	00004797          	auipc	a5,0x4
ffffffffc0200a60:	5ec7a223          	sw	a2,1508(a5) # ffffffffc0205040 <max_order>
    for (size_t j = 0; j < header_pages_num; j++) {
ffffffffc0200a64:	00269313          	slli	t1,a3,0x2
ffffffffc0200a68:	00d30833          	add	a6,t1,a3
ffffffffc0200a6c:	080e                	slli	a6,a6,0x3
ffffffffc0200a6e:	872a                	mv	a4,a0
ffffffffc0200a70:	982a                	add	a6,a6,a0
        ClearPageProperty(base + j);
ffffffffc0200a72:	671c                	ld	a5,8(a4)
    for (size_t j = 0; j < header_pages_num; j++) {
ffffffffc0200a74:	02870713          	addi	a4,a4,40
        ClearPageProperty(base + j);
ffffffffc0200a78:	9bf5                	andi	a5,a5,-3
ffffffffc0200a7a:	0017e793          	ori	a5,a5,1
ffffffffc0200a7e:	fef73023          	sd	a5,-32(a4)
    for (size_t j = 0; j < header_pages_num; j++) {
ffffffffc0200a82:	fee818e3          	bne	a6,a4,ffffffffc0200a72 <buddy_init_memmap+0x38>
    for (struct Page *q = r; q < base + n; q++) {
ffffffffc0200a86:	00259893          	slli	a7,a1,0x2
    struct Page *r = base + header_pages_num;
ffffffffc0200a8a:	00d30833          	add	a6,t1,a3
    for (struct Page *q = r; q < base + n; q++) {
ffffffffc0200a8e:	98ae                	add	a7,a7,a1
    struct Page *r = base + header_pages_num;
ffffffffc0200a90:	080e                	slli	a6,a6,0x3
    for (struct Page *q = r; q < base + n; q++) {
ffffffffc0200a92:	088e                	slli	a7,a7,0x3
    struct Page *r = base + header_pages_num;
ffffffffc0200a94:	982a                	add	a6,a6,a0
    for (struct Page *q = r; q < base + n; q++) {
ffffffffc0200a96:	98aa                	add	a7,a7,a0
ffffffffc0200a98:	87c2                	mv	a5,a6
ffffffffc0200a9a:	03187263          	bgeu	a6,a7,ffffffffc0200abe <buddy_init_memmap+0x84>
        if (PageReserved(q)) {
ffffffffc0200a9e:	6798                	ld	a4,8(a5)
ffffffffc0200aa0:	00177313          	andi	t1,a4,1
ffffffffc0200aa4:	00030363          	beqz	t1,ffffffffc0200aaa <buddy_init_memmap+0x70>
            ClearPageReserved(q);
ffffffffc0200aa8:	9b79                	andi	a4,a4,-2
        ClearPageProperty(q);
ffffffffc0200aaa:	9b75                	andi	a4,a4,-3
ffffffffc0200aac:	e798                	sd	a4,8(a5)
        q->property = 0;
ffffffffc0200aae:	0007a823          	sw	zero,16(a5)
static inline void set_page_ref(struct Page *page, int val) { page->ref = val; }
ffffffffc0200ab2:	0007a023          	sw	zero,0(a5)
    for (struct Page *q = r; q < base + n; q++) {
ffffffffc0200ab6:	02878793          	addi	a5,a5,40
ffffffffc0200aba:	ff17e2e3          	bltu	a5,a7,ffffffffc0200a9e <buddy_init_memmap+0x64>
static inline ppn_t page2ppn(struct Page *page) { return page - pages + nbase; }
ffffffffc0200abe:	00004e17          	auipc	t3,0x4
ffffffffc0200ac2:	592e3e03          	ld	t3,1426(t3) # ffffffffc0205050 <pages>
ffffffffc0200ac6:	41c507b3          	sub	a5,a0,t3
ffffffffc0200aca:	878d                	srai	a5,a5,0x3
ffffffffc0200acc:	00001e97          	auipc	t4,0x1
ffffffffc0200ad0:	1b4ebe83          	ld	t4,436(t4) # ffffffffc0201c80 <error_string+0x38>
ffffffffc0200ad4:	03d787b3          	mul	a5,a5,t4
ffffffffc0200ad8:	00001f17          	auipc	t5,0x1
ffffffffc0200adc:	1b0f3f03          	ld	t5,432(t5) # ffffffffc0201c88 <nbase>
    free_list = (list_entry_t *)(freelist_head + va_pa_offset);
ffffffffc0200ae0:	00004717          	auipc	a4,0x4
ffffffffc0200ae4:	59073703          	ld	a4,1424(a4) # ffffffffc0205070 <va_pa_offset>
ffffffffc0200ae8:	97fa                	add	a5,a5,t5
    return page2ppn(page) << PGSHIFT;
ffffffffc0200aea:	07b2                	slli	a5,a5,0xc
ffffffffc0200aec:	97ba                	add	a5,a5,a4
ffffffffc0200aee:	00004717          	auipc	a4,0x4
ffffffffc0200af2:	54f73523          	sd	a5,1354(a4) # ffffffffc0205038 <free_list>
ffffffffc0200af6:	82be                	mv	t0,a5
    if (free_list!=NULL) {
ffffffffc0200af8:	cf99                	beqz	a5,ffffffffc0200b16 <buddy_init_memmap+0xdc>
        for (int i = 0; i <= max_order; i++) {
ffffffffc0200afa:	00064e63          	bltz	a2,ffffffffc0200b16 <buddy_init_memmap+0xdc>
ffffffffc0200afe:	01078513          	addi	a0,a5,16
ffffffffc0200b02:	00461713          	slli	a4,a2,0x4
ffffffffc0200b06:	972a                	add	a4,a4,a0
ffffffffc0200b08:	a011                	j	ffffffffc0200b0c <buddy_init_memmap+0xd2>
ffffffffc0200b0a:	0541                	addi	a0,a0,16
    elm->prev = elm->next = elm;
ffffffffc0200b0c:	e79c                	sd	a5,8(a5)
ffffffffc0200b0e:	e39c                	sd	a5,0(a5)
ffffffffc0200b10:	87aa                	mv	a5,a0
ffffffffc0200b12:	fea71ce3          	bne	a4,a0,ffffffffc0200b0a <buddy_init_memmap+0xd0>
    buddy_nr_free = 0;
ffffffffc0200b16:	00004797          	auipc	a5,0x4
ffffffffc0200b1a:	5007bd23          	sd	zero,1306(a5) # ffffffffc0205030 <buddy_nr_free>
    size_t remain_pages = n - header_pages_num;
ffffffffc0200b1e:	40d58533          	sub	a0,a1,a3
    while (remain_pages > 0) {
ffffffffc0200b22:	4f81                	li	t6,0
        while ((1UL << (order + 1)) <= remain_pages) {
ffffffffc0200b24:	4885                	li	a7,1
        while (order > 0 && (idx & ((1UL << order) - 1)) != 0) {
ffffffffc0200b26:	02800393          	li	t2,40
ffffffffc0200b2a:	537d                	li	t1,-1
    while (remain_pages > 0) {
ffffffffc0200b2c:	0ad58663          	beq	a1,a3,ffffffffc0200bd8 <buddy_init_memmap+0x19e>
static void buddy_init_memmap(struct Page *base, size_t n) {
ffffffffc0200b30:	1141                	addi	sp,sp,-16
ffffffffc0200b32:	e422                	sd	s0,8(sp)
static inline ppn_t page2ppn(struct Page *page) { return page - pages + nbase; }
ffffffffc0200b34:	41c80633          	sub	a2,a6,t3
ffffffffc0200b38:	860d                	srai	a2,a2,0x3
ffffffffc0200b3a:	03d60633          	mul	a2,a2,t4
        int order = 0;
ffffffffc0200b3e:	4701                	li	a4,0
ffffffffc0200b40:	967a                	add	a2,a2,t5
        while ((1UL << (order + 1)) <= remain_pages) {
ffffffffc0200b42:	87ba                	mv	a5,a4
ffffffffc0200b44:	2705                	addiw	a4,a4,1
ffffffffc0200b46:	00e896b3          	sll	a3,a7,a4
ffffffffc0200b4a:	fed57ce3          	bgeu	a0,a3,ffffffffc0200b42 <buddy_init_memmap+0x108>
        while (order > 0 && (idx & ((1UL << order) - 1)) != 0) {
ffffffffc0200b4e:	c385                	beqz	a5,ffffffffc0200b6e <buddy_init_memmap+0x134>
ffffffffc0200b50:	00f31733          	sll	a4,t1,a5
ffffffffc0200b54:	fff74713          	not	a4,a4
ffffffffc0200b58:	8f71                	and	a4,a4,a2
ffffffffc0200b5a:	e319                	bnez	a4,ffffffffc0200b60 <buddy_init_memmap+0x126>
ffffffffc0200b5c:	a0a5                	j	ffffffffc0200bc4 <buddy_init_memmap+0x18a>
ffffffffc0200b5e:	cb29                	beqz	a4,ffffffffc0200bb0 <buddy_init_memmap+0x176>
            order--;
ffffffffc0200b60:	37fd                	addiw	a5,a5,-1
        while (order > 0 && (idx & ((1UL << order) - 1)) != 0) {
ffffffffc0200b62:	00f31733          	sll	a4,t1,a5
ffffffffc0200b66:	fff74713          	not	a4,a4
ffffffffc0200b6a:	8f71                	and	a4,a4,a2
ffffffffc0200b6c:	fbed                	bnez	a5,ffffffffc0200b5e <buddy_init_memmap+0x124>
    free_list = (list_entry_t *)(freelist_head + va_pa_offset);
ffffffffc0200b6e:	8716                	mv	a4,t0
ffffffffc0200b70:	02800693          	li	a3,40
ffffffffc0200b74:	4585                	li	a1,1
ffffffffc0200b76:	4401                	li	s0,0
        SetPageProperty(p);
ffffffffc0200b78:	00883783          	ld	a5,8(a6)
    __list_add(elm, listelm, listelm->next);
ffffffffc0200b7c:	6710                	ld	a2,8(a4)
        p->property = order;
ffffffffc0200b7e:	00882823          	sw	s0,16(a6)
        SetPageProperty(p);
ffffffffc0200b82:	0027e793          	ori	a5,a5,2
ffffffffc0200b86:	00f83423          	sd	a5,8(a6)
        list_add(&free_list[order], &p->page_link);
ffffffffc0200b8a:	01880793          	addi	a5,a6,24
    prev->next = next->prev = elm;
ffffffffc0200b8e:	e21c                	sd	a5,0(a2)
ffffffffc0200b90:	e71c                	sd	a5,8(a4)
    elm->next = next;
ffffffffc0200b92:	02c83023          	sd	a2,32(a6)
    elm->prev = prev;
ffffffffc0200b96:	00e83c23          	sd	a4,24(a6)
        remain_pages -= (1UL << order);
ffffffffc0200b9a:	8d0d                	sub	a0,a0,a1
        buddy_nr_free += (1UL << order);
ffffffffc0200b9c:	9fae                	add	t6,t6,a1
        p += (1UL << order);
ffffffffc0200b9e:	9836                	add	a6,a6,a3
    while (remain_pages > 0) {
ffffffffc0200ba0:	f951                	bnez	a0,ffffffffc0200b34 <buddy_init_memmap+0xfa>
}
ffffffffc0200ba2:	6422                	ld	s0,8(sp)
ffffffffc0200ba4:	00004797          	auipc	a5,0x4
ffffffffc0200ba8:	49f7b623          	sd	t6,1164(a5) # ffffffffc0205030 <buddy_nr_free>
ffffffffc0200bac:	0141                	addi	sp,sp,16
ffffffffc0200bae:	8082                	ret
        list_add(&free_list[order], &p->page_link);
ffffffffc0200bb0:	00479713          	slli	a4,a5,0x4
        p->property = order;
ffffffffc0200bb4:	0007841b          	sext.w	s0,a5
        list_add(&free_list[order], &p->page_link);
ffffffffc0200bb8:	9716                	add	a4,a4,t0
        buddy_nr_free += (1UL << order);
ffffffffc0200bba:	00f895b3          	sll	a1,a7,a5
        p += (1UL << order);
ffffffffc0200bbe:	00f396b3          	sll	a3,t2,a5
ffffffffc0200bc2:	bf5d                	j	ffffffffc0200b78 <buddy_init_memmap+0x13e>
        list_add(&free_list[order], &p->page_link);
ffffffffc0200bc4:	00479713          	slli	a4,a5,0x4
        p->property = order;
ffffffffc0200bc8:	0007841b          	sext.w	s0,a5
        list_add(&free_list[order], &p->page_link);
ffffffffc0200bcc:	9716                	add	a4,a4,t0
        buddy_nr_free += (1UL << order);
ffffffffc0200bce:	00f895b3          	sll	a1,a7,a5
        p += (1UL << order);
ffffffffc0200bd2:	00f396b3          	sll	a3,t2,a5
ffffffffc0200bd6:	b74d                	j	ffffffffc0200b78 <buddy_init_memmap+0x13e>
ffffffffc0200bd8:	8082                	ret
ffffffffc0200bda:	00004617          	auipc	a2,0x4
ffffffffc0200bde:	46662603          	lw	a2,1126(a2) # ffffffffc0205040 <max_order>
    size_t header_size = (max_order + 1) * sizeof(list_entry_t);
ffffffffc0200be2:	0016069b          	addiw	a3,a2,1
    size_t header_pages_num = (header_size + PGSIZE - 1) / PGSIZE;
ffffffffc0200be6:	6785                	lui	a5,0x1
    size_t header_size = (max_order + 1) * sizeof(list_entry_t);
ffffffffc0200be8:	0692                	slli	a3,a3,0x4
    size_t header_pages_num = (header_size + PGSIZE - 1) / PGSIZE;
ffffffffc0200bea:	17fd                	addi	a5,a5,-1
ffffffffc0200bec:	96be                	add	a3,a3,a5
ffffffffc0200bee:	82b1                	srli	a3,a3,0xc
    for (size_t j = 0; j < header_pages_num; j++) {
ffffffffc0200bf0:	e6069ae3          	bnez	a3,ffffffffc0200a64 <buddy_init_memmap+0x2a>
ffffffffc0200bf4:	4301                	li	t1,0
ffffffffc0200bf6:	bd41                	j	ffffffffc0200a86 <buddy_init_memmap+0x4c>

ffffffffc0200bf8 <buddy_check>:

static void buddy_check(void) {
ffffffffc0200bf8:	7109                	addi	sp,sp,-384
ffffffffc0200bfa:	faa2                	sd	s0,368(sp)
ffffffffc0200bfc:	f6a6                	sd	s1,360(sp)
ffffffffc0200bfe:	f2ca                	sd	s2,352(sp)
ffffffffc0200c00:	eece                	sd	s3,344(sp)
ffffffffc0200c02:	ead2                	sd	s4,336(sp)
ffffffffc0200c04:	e6d6                	sd	s5,328(sp)
ffffffffc0200c06:	e2da                	sd	s6,320(sp)
ffffffffc0200c08:	fe86                	sd	ra,376(sp)
ffffffffc0200c0a:	fe5e                	sd	s7,312(sp)
    basic_check(); // 原有结构检查
ffffffffc0200c0c:	ad3ff0ef          	jal	ra,ffffffffc02006de <basic_check>
    size_t block_sizes[16];   // 对应块大小
    int num_blocks = 0;

    
    // 2. 分配一些块
    size_t alloc_sizes[] = {1, 2, 3, 4, 5};  // 单位页
ffffffffc0200c10:	00001797          	auipc	a5,0x1
ffffffffc0200c14:	cb078793          	addi	a5,a5,-848 # ffffffffc02018c0 <etext+0x49e>
ffffffffc0200c18:	638c                	ld	a1,0(a5)
ffffffffc0200c1a:	6790                	ld	a2,8(a5)
ffffffffc0200c1c:	6b94                	ld	a3,16(a5)
ffffffffc0200c1e:	6f98                	ld	a4,24(a5)
    return buddy_nr_free;
ffffffffc0200c20:	00004997          	auipc	s3,0x4
ffffffffc0200c24:	41098993          	addi	s3,s3,1040 # ffffffffc0205030 <buddy_nr_free>
    size_t alloc_sizes[] = {1, 2, 3, 4, 5};  // 单位页
ffffffffc0200c28:	739c                	ld	a5,32(a5)
    return buddy_nr_free;
ffffffffc0200c2a:	0009ba03          	ld	s4,0(s3)
    size_t alloc_sizes[] = {1, 2, 3, 4, 5};  // 单位页
ffffffffc0200c2e:	03010913          	addi	s2,sp,48
ffffffffc0200c32:	e42e                	sd	a1,8(sp)
ffffffffc0200c34:	e832                	sd	a2,16(sp)
ffffffffc0200c36:	ec36                	sd	a3,24(sp)
ffffffffc0200c38:	f03a                	sd	a4,32(sp)
ffffffffc0200c3a:	f43e                	sd	a5,40(sp)
    int n_alloc_sizes = sizeof(alloc_sizes)/sizeof(alloc_sizes[0]);

    for (int i=0; i<n_alloc_sizes; i++) {
ffffffffc0200c3c:	00810a93          	addi	s5,sp,8
ffffffffc0200c40:	1924                	addi	s1,sp,184
    size_t alloc_sizes[] = {1, 2, 3, 4, 5};  // 单位页
ffffffffc0200c42:	8b4a                	mv	s6,s2
    while (s < n) { 
ffffffffc0200c44:	4405                	li	s0,1
        struct Page *p = buddy_alloc_pages(alloc_sizes[i]);
ffffffffc0200c46:	000abb83          	ld	s7,0(s5)
ffffffffc0200c4a:	855e                	mv	a0,s7
ffffffffc0200c4c:	9b7ff0ef          	jal	ra,ffffffffc0200602 <buddy_alloc_pages>
        assert(p != NULL);  // 确保分配成功
ffffffffc0200c50:	c179                	beqz	a0,ffffffffc0200d16 <buddy_check+0x11e>
        blocks[num_blocks] = p;
ffffffffc0200c52:	00ab3023          	sd	a0,0(s6) # 10000 <kern_entry-0xffffffffc01f0000>
        block_sizes[num_blocks] = alloc_sizes[i];
ffffffffc0200c56:	ff74bc23          	sd	s7,-8(s1)
ffffffffc0200c5a:	1910                	addi	a2,sp,176
        num_blocks++;

        // 分配后空闲页数应减少
        size_t expected_free = total_free_before;
ffffffffc0200c5c:	85d2                	mv	a1,s4
        for (int j=0; j<num_blocks; j++)
            expected_free -= (1UL << cal_buddy_order(block_sizes[j]));
ffffffffc0200c5e:	6214                	ld	a3,0(a2)
    while (s < n) { 
ffffffffc0200c60:	06d47863          	bgeu	s0,a3,ffffffffc0200cd0 <buddy_check+0xd8>
    int k = 0;
ffffffffc0200c64:	4701                	li	a4,0
    size_t s = 1;
ffffffffc0200c66:	4785                	li	a5,1
        s *= 2; 
ffffffffc0200c68:	0786                	slli	a5,a5,0x1
        k++; 
ffffffffc0200c6a:	2705                	addiw	a4,a4,1
    while (s < n) { 
ffffffffc0200c6c:	fed7eee3          	bltu	a5,a3,ffffffffc0200c68 <buddy_check+0x70>
            expected_free -= (1UL << cal_buddy_order(block_sizes[j]));
ffffffffc0200c70:	00e41733          	sll	a4,s0,a4
        for (int j=0; j<num_blocks; j++)
ffffffffc0200c74:	0621                	addi	a2,a2,8
            expected_free -= (1UL << cal_buddy_order(block_sizes[j]));
ffffffffc0200c76:	8d99                	sub	a1,a1,a4
        for (int j=0; j<num_blocks; j++)
ffffffffc0200c78:	fe9613e3          	bne	a2,s1,ffffffffc0200c5e <buddy_check+0x66>
        assert(buddy_nr_free_pages() == expected_free);
ffffffffc0200c7c:	0009b783          	ld	a5,0(s3)
ffffffffc0200c80:	10b79b63          	bne	a5,a1,ffffffffc0200d96 <buddy_check+0x19e>
    for (int i=0; i<n_alloc_sizes; i++) {
ffffffffc0200c84:	0aa1                	addi	s5,s5,8
ffffffffc0200c86:	00860493          	addi	s1,a2,8
ffffffffc0200c8a:	0b21                	addi	s6,s6,8
ffffffffc0200c8c:	fb591de3          	bne	s2,s5,ffffffffc0200c46 <buddy_check+0x4e>
    }

    
    // 3. 释放块
    for (int i=num_blocks-1; i>=0; i--) {
        buddy_free_pages(blocks[i], block_sizes[i]);
ffffffffc0200c90:	65ce                	ld	a1,208(sp)
ffffffffc0200c92:	0880                	addi	s0,sp,80
ffffffffc0200c94:	0984                	addi	s1,sp,208
ffffffffc0200c96:	6008                	ld	a0,0(s0)
    assert(n > 0);
ffffffffc0200c98:	cd81                	beqz	a1,ffffffffc0200cb0 <buddy_check+0xb8>
ffffffffc0200c9a:	bc7ff0ef          	jal	ra,ffffffffc0200860 <buddy_free_pages.part.0>
    for (int i=num_blocks-1; i>=0; i--) {
ffffffffc0200c9e:	14e1                	addi	s1,s1,-8
ffffffffc0200ca0:	ff840793          	addi	a5,s0,-8
ffffffffc0200ca4:	03240863          	beq	s0,s2,ffffffffc0200cd4 <buddy_check+0xdc>
        buddy_free_pages(blocks[i], block_sizes[i]);
ffffffffc0200ca8:	608c                	ld	a1,0(s1)
ffffffffc0200caa:	843e                	mv	s0,a5
ffffffffc0200cac:	6008                	ld	a0,0(s0)
    assert(n > 0);
ffffffffc0200cae:	f5f5                	bnez	a1,ffffffffc0200c9a <buddy_check+0xa2>
ffffffffc0200cb0:	00001697          	auipc	a3,0x1
ffffffffc0200cb4:	b3068693          	addi	a3,a3,-1232 # ffffffffc02017e0 <etext+0x3be>
ffffffffc0200cb8:	00001617          	auipc	a2,0x1
ffffffffc0200cbc:	9e860613          	addi	a2,a2,-1560 # ffffffffc02016a0 <etext+0x27e>
ffffffffc0200cc0:	07400593          	li	a1,116
ffffffffc0200cc4:	00001517          	auipc	a0,0x1
ffffffffc0200cc8:	9f450513          	addi	a0,a0,-1548 # ffffffffc02016b8 <etext+0x296>
ffffffffc0200ccc:	cf6ff0ef          	jal	ra,ffffffffc02001c2 <__panic>
    while (s < n) { 
ffffffffc0200cd0:	4705                	li	a4,1
ffffffffc0200cd2:	b74d                	j	ffffffffc0200c74 <buddy_check+0x7c>
    return buddy_nr_free;
ffffffffc0200cd4:	0009b403          	ld	s0,0(s3)
        // 释放后空闲页数增加
        total_free_before = buddy_nr_free_pages();
    }

    // 4. 尝试分配整个空闲区（最大块）
    struct Page *max_block = buddy_alloc_pages(total_free_before);
ffffffffc0200cd8:	8522                	mv	a0,s0
ffffffffc0200cda:	929ff0ef          	jal	ra,ffffffffc0200602 <buddy_alloc_pages>
    if (max_block != NULL) {
ffffffffc0200cde:	cd01                	beqz	a0,ffffffffc0200cf6 <buddy_check+0xfe>
        assert(buddy_nr_free_pages() == 0); // 全部分配
ffffffffc0200ce0:	0009b783          	ld	a5,0(s3)
ffffffffc0200ce4:	ebc9                	bnez	a5,ffffffffc0200d76 <buddy_check+0x17e>
    assert(n > 0);
ffffffffc0200ce6:	d469                	beqz	s0,ffffffffc0200cb0 <buddy_check+0xb8>
ffffffffc0200ce8:	85a2                	mv	a1,s0
ffffffffc0200cea:	b77ff0ef          	jal	ra,ffffffffc0200860 <buddy_free_pages.part.0>
        buddy_free_pages(max_block, total_free_before);
        assert(buddy_nr_free_pages() == total_free_before); // 释放回去
ffffffffc0200cee:	0009b783          	ld	a5,0(s3)
ffffffffc0200cf2:	06f41263          	bne	s0,a5,ffffffffc0200d56 <buddy_check+0x15e>
    }
   
    // 5. 边界情况测试
    assert(buddy_alloc_pages(0) == NULL); // 分配 0 页应返回 NULL
    assert(buddy_alloc_pages(total_free_before + 1) == NULL); // 超过剩余页数应返回 NULL
ffffffffc0200cf6:	00140513          	addi	a0,s0,1
ffffffffc0200cfa:	909ff0ef          	jal	ra,ffffffffc0200602 <buddy_alloc_pages>
ffffffffc0200cfe:	ed05                	bnez	a0,ffffffffc0200d36 <buddy_check+0x13e>

    
    // 6. 最终状态检查
    basic_check(); // 最后调用结构检查，确保链表、property 和总页数正确
}
ffffffffc0200d00:	7456                	ld	s0,368(sp)
ffffffffc0200d02:	70f6                	ld	ra,376(sp)
ffffffffc0200d04:	74b6                	ld	s1,360(sp)
ffffffffc0200d06:	7916                	ld	s2,352(sp)
ffffffffc0200d08:	69f6                	ld	s3,344(sp)
ffffffffc0200d0a:	6a56                	ld	s4,336(sp)
ffffffffc0200d0c:	6ab6                	ld	s5,328(sp)
ffffffffc0200d0e:	6b16                	ld	s6,320(sp)
ffffffffc0200d10:	7bf2                	ld	s7,312(sp)
ffffffffc0200d12:	6119                	addi	sp,sp,384
    basic_check(); // 最后调用结构检查，确保链表、property 和总页数正确
ffffffffc0200d14:	b2e9                	j	ffffffffc02006de <basic_check>
        assert(p != NULL);  // 确保分配成功
ffffffffc0200d16:	00001697          	auipc	a3,0x1
ffffffffc0200d1a:	ad268693          	addi	a3,a3,-1326 # ffffffffc02017e8 <etext+0x3c6>
ffffffffc0200d1e:	00001617          	auipc	a2,0x1
ffffffffc0200d22:	98260613          	addi	a2,a2,-1662 # ffffffffc02016a0 <etext+0x27e>
ffffffffc0200d26:	0dd00593          	li	a1,221
ffffffffc0200d2a:	00001517          	auipc	a0,0x1
ffffffffc0200d2e:	98e50513          	addi	a0,a0,-1650 # ffffffffc02016b8 <etext+0x296>
ffffffffc0200d32:	c90ff0ef          	jal	ra,ffffffffc02001c2 <__panic>
    assert(buddy_alloc_pages(total_free_before + 1) == NULL); // 超过剩余页数应返回 NULL
ffffffffc0200d36:	00001697          	auipc	a3,0x1
ffffffffc0200d3a:	b3a68693          	addi	a3,a3,-1222 # ffffffffc0201870 <etext+0x44e>
ffffffffc0200d3e:	00001617          	auipc	a2,0x1
ffffffffc0200d42:	96260613          	addi	a2,a2,-1694 # ffffffffc02016a0 <etext+0x27e>
ffffffffc0200d46:	0fc00593          	li	a1,252
ffffffffc0200d4a:	00001517          	auipc	a0,0x1
ffffffffc0200d4e:	96e50513          	addi	a0,a0,-1682 # ffffffffc02016b8 <etext+0x296>
ffffffffc0200d52:	c70ff0ef          	jal	ra,ffffffffc02001c2 <__panic>
        assert(buddy_nr_free_pages() == total_free_before); // 释放回去
ffffffffc0200d56:	00001697          	auipc	a3,0x1
ffffffffc0200d5a:	aea68693          	addi	a3,a3,-1302 # ffffffffc0201840 <etext+0x41e>
ffffffffc0200d5e:	00001617          	auipc	a2,0x1
ffffffffc0200d62:	94260613          	addi	a2,a2,-1726 # ffffffffc02016a0 <etext+0x27e>
ffffffffc0200d66:	0f700593          	li	a1,247
ffffffffc0200d6a:	00001517          	auipc	a0,0x1
ffffffffc0200d6e:	94e50513          	addi	a0,a0,-1714 # ffffffffc02016b8 <etext+0x296>
ffffffffc0200d72:	c50ff0ef          	jal	ra,ffffffffc02001c2 <__panic>
        assert(buddy_nr_free_pages() == 0); // 全部分配
ffffffffc0200d76:	00001697          	auipc	a3,0x1
ffffffffc0200d7a:	aaa68693          	addi	a3,a3,-1366 # ffffffffc0201820 <etext+0x3fe>
ffffffffc0200d7e:	00001617          	auipc	a2,0x1
ffffffffc0200d82:	92260613          	addi	a2,a2,-1758 # ffffffffc02016a0 <etext+0x27e>
ffffffffc0200d86:	0f500593          	li	a1,245
ffffffffc0200d8a:	00001517          	auipc	a0,0x1
ffffffffc0200d8e:	92e50513          	addi	a0,a0,-1746 # ffffffffc02016b8 <etext+0x296>
ffffffffc0200d92:	c30ff0ef          	jal	ra,ffffffffc02001c2 <__panic>
        assert(buddy_nr_free_pages() == expected_free);
ffffffffc0200d96:	00001697          	auipc	a3,0x1
ffffffffc0200d9a:	a6268693          	addi	a3,a3,-1438 # ffffffffc02017f8 <etext+0x3d6>
ffffffffc0200d9e:	00001617          	auipc	a2,0x1
ffffffffc0200da2:	90260613          	addi	a2,a2,-1790 # ffffffffc02016a0 <etext+0x27e>
ffffffffc0200da6:	0e600593          	li	a1,230
ffffffffc0200daa:	00001517          	auipc	a0,0x1
ffffffffc0200dae:	90e50513          	addi	a0,a0,-1778 # ffffffffc02016b8 <etext+0x296>
ffffffffc0200db2:	c10ff0ef          	jal	ra,ffffffffc02001c2 <__panic>

ffffffffc0200db6 <pmm_init>:

static void check_alloc_page(void);

// init_pmm_manager - initialize a pmm_manager instance
static void init_pmm_manager(void) {
    pmm_manager = &buddy_pmm_manager;
ffffffffc0200db6:	00001797          	auipc	a5,0x1
ffffffffc0200dba:	b3278793          	addi	a5,a5,-1230 # ffffffffc02018e8 <buddy_pmm_manager>
    cprintf("memory management: %s\n", pmm_manager->name);
ffffffffc0200dbe:	638c                	ld	a1,0(a5)
        init_memmap(pa2page(mem_begin), (mem_end - mem_begin) / PGSIZE);
    }
}

/* pmm_init - initialize the physical memory management */
void pmm_init(void) {
ffffffffc0200dc0:	7179                	addi	sp,sp,-48
ffffffffc0200dc2:	f022                	sd	s0,32(sp)
    cprintf("memory management: %s\n", pmm_manager->name);
ffffffffc0200dc4:	00001517          	auipc	a0,0x1
ffffffffc0200dc8:	b5c50513          	addi	a0,a0,-1188 # ffffffffc0201920 <buddy_pmm_manager+0x38>
    pmm_manager = &buddy_pmm_manager;
ffffffffc0200dcc:	00004417          	auipc	s0,0x4
ffffffffc0200dd0:	28c40413          	addi	s0,s0,652 # ffffffffc0205058 <pmm_manager>
void pmm_init(void) {
ffffffffc0200dd4:	f406                	sd	ra,40(sp)
ffffffffc0200dd6:	ec26                	sd	s1,24(sp)
ffffffffc0200dd8:	e44e                	sd	s3,8(sp)
ffffffffc0200dda:	e84a                	sd	s2,16(sp)
ffffffffc0200ddc:	e052                	sd	s4,0(sp)
    pmm_manager = &buddy_pmm_manager;
ffffffffc0200dde:	e01c                	sd	a5,0(s0)
    cprintf("memory management: %s\n", pmm_manager->name);
ffffffffc0200de0:	b6cff0ef          	jal	ra,ffffffffc020014c <cprintf>
    pmm_manager->init();
ffffffffc0200de4:	601c                	ld	a5,0(s0)
    va_pa_offset = PHYSICAL_MEMORY_OFFSET;
ffffffffc0200de6:	00004497          	auipc	s1,0x4
ffffffffc0200dea:	28a48493          	addi	s1,s1,650 # ffffffffc0205070 <va_pa_offset>
    pmm_manager->init();
ffffffffc0200dee:	679c                	ld	a5,8(a5)
ffffffffc0200df0:	9782                	jalr	a5
    va_pa_offset = PHYSICAL_MEMORY_OFFSET;
ffffffffc0200df2:	57f5                	li	a5,-3
ffffffffc0200df4:	07fa                	slli	a5,a5,0x1e
ffffffffc0200df6:	e09c                	sd	a5,0(s1)
    uint64_t mem_begin = get_memory_base();
ffffffffc0200df8:	fc4ff0ef          	jal	ra,ffffffffc02005bc <get_memory_base>
ffffffffc0200dfc:	89aa                	mv	s3,a0
    uint64_t mem_size  = get_memory_size();
ffffffffc0200dfe:	fc8ff0ef          	jal	ra,ffffffffc02005c6 <get_memory_size>
    if (mem_size == 0) {
ffffffffc0200e02:	14050d63          	beqz	a0,ffffffffc0200f5c <pmm_init+0x1a6>
    uint64_t mem_end   = mem_begin + mem_size;
ffffffffc0200e06:	892a                	mv	s2,a0
    cprintf("physcial memory map:\n");
ffffffffc0200e08:	00001517          	auipc	a0,0x1
ffffffffc0200e0c:	b6050513          	addi	a0,a0,-1184 # ffffffffc0201968 <buddy_pmm_manager+0x80>
ffffffffc0200e10:	b3cff0ef          	jal	ra,ffffffffc020014c <cprintf>
    uint64_t mem_end   = mem_begin + mem_size;
ffffffffc0200e14:	01298a33          	add	s4,s3,s2
    cprintf("  memory: 0x%016lx, [0x%016lx, 0x%016lx].\n", mem_size, mem_begin,
ffffffffc0200e18:	864e                	mv	a2,s3
ffffffffc0200e1a:	fffa0693          	addi	a3,s4,-1
ffffffffc0200e1e:	85ca                	mv	a1,s2
ffffffffc0200e20:	00001517          	auipc	a0,0x1
ffffffffc0200e24:	b6050513          	addi	a0,a0,-1184 # ffffffffc0201980 <buddy_pmm_manager+0x98>
ffffffffc0200e28:	b24ff0ef          	jal	ra,ffffffffc020014c <cprintf>
    npage = maxpa / PGSIZE;
ffffffffc0200e2c:	c80007b7          	lui	a5,0xc8000
ffffffffc0200e30:	8652                	mv	a2,s4
ffffffffc0200e32:	0d47e463          	bltu	a5,s4,ffffffffc0200efa <pmm_init+0x144>
ffffffffc0200e36:	00005797          	auipc	a5,0x5
ffffffffc0200e3a:	24178793          	addi	a5,a5,577 # ffffffffc0206077 <end+0xfff>
ffffffffc0200e3e:	757d                	lui	a0,0xfffff
ffffffffc0200e40:	8d7d                	and	a0,a0,a5
ffffffffc0200e42:	8231                	srli	a2,a2,0xc
ffffffffc0200e44:	00004797          	auipc	a5,0x4
ffffffffc0200e48:	20c7b223          	sd	a2,516(a5) # ffffffffc0205048 <npage>
    pages = (struct Page *)ROUNDUP((void *)end, PGSIZE);
ffffffffc0200e4c:	00004797          	auipc	a5,0x4
ffffffffc0200e50:	20a7b223          	sd	a0,516(a5) # ffffffffc0205050 <pages>
    for (size_t i = 0; i < npage - nbase; i++) {
ffffffffc0200e54:	000807b7          	lui	a5,0x80
ffffffffc0200e58:	002005b7          	lui	a1,0x200
ffffffffc0200e5c:	02f60563          	beq	a2,a5,ffffffffc0200e86 <pmm_init+0xd0>
ffffffffc0200e60:	00261593          	slli	a1,a2,0x2
ffffffffc0200e64:	00c586b3          	add	a3,a1,a2
ffffffffc0200e68:	fec007b7          	lui	a5,0xfec00
ffffffffc0200e6c:	97aa                	add	a5,a5,a0
ffffffffc0200e6e:	068e                	slli	a3,a3,0x3
ffffffffc0200e70:	96be                	add	a3,a3,a5
ffffffffc0200e72:	87aa                	mv	a5,a0
        SetPageReserved(pages + i);
ffffffffc0200e74:	6798                	ld	a4,8(a5)
    for (size_t i = 0; i < npage - nbase; i++) {
ffffffffc0200e76:	02878793          	addi	a5,a5,40 # fffffffffec00028 <end+0x3e9fafb0>
        SetPageReserved(pages + i);
ffffffffc0200e7a:	00176713          	ori	a4,a4,1
ffffffffc0200e7e:	fee7b023          	sd	a4,-32(a5)
    for (size_t i = 0; i < npage - nbase; i++) {
ffffffffc0200e82:	fef699e3          	bne	a3,a5,ffffffffc0200e74 <pmm_init+0xbe>
    uintptr_t freemem = PADDR((uintptr_t)pages + sizeof(struct Page) * (npage - nbase));
ffffffffc0200e86:	95b2                	add	a1,a1,a2
ffffffffc0200e88:	fec006b7          	lui	a3,0xfec00
ffffffffc0200e8c:	96aa                	add	a3,a3,a0
ffffffffc0200e8e:	058e                	slli	a1,a1,0x3
ffffffffc0200e90:	96ae                	add	a3,a3,a1
ffffffffc0200e92:	c02007b7          	lui	a5,0xc0200
ffffffffc0200e96:	0af6e763          	bltu	a3,a5,ffffffffc0200f44 <pmm_init+0x18e>
ffffffffc0200e9a:	6098                	ld	a4,0(s1)
    mem_end = ROUNDDOWN(mem_end, PGSIZE);
ffffffffc0200e9c:	77fd                	lui	a5,0xfffff
ffffffffc0200e9e:	00fa75b3          	and	a1,s4,a5
    uintptr_t freemem = PADDR((uintptr_t)pages + sizeof(struct Page) * (npage - nbase));
ffffffffc0200ea2:	8e99                	sub	a3,a3,a4
    if (freemem < mem_end) {
ffffffffc0200ea4:	04b6ee63          	bltu	a3,a1,ffffffffc0200f00 <pmm_init+0x14a>
    satp_physical = PADDR(satp_virtual);
    cprintf("satp virtual address: 0x%016lx\nsatp physical address: 0x%016lx\n", satp_virtual, satp_physical);
}

static void check_alloc_page(void) {
    pmm_manager->check();
ffffffffc0200ea8:	601c                	ld	a5,0(s0)
ffffffffc0200eaa:	7b9c                	ld	a5,48(a5)
ffffffffc0200eac:	9782                	jalr	a5
    cprintf("check_alloc_page() succeeded!\n");
ffffffffc0200eae:	00001517          	auipc	a0,0x1
ffffffffc0200eb2:	b2a50513          	addi	a0,a0,-1238 # ffffffffc02019d8 <buddy_pmm_manager+0xf0>
ffffffffc0200eb6:	a96ff0ef          	jal	ra,ffffffffc020014c <cprintf>
    satp_virtual = (pte_t*)boot_page_table_sv39;
ffffffffc0200eba:	00003597          	auipc	a1,0x3
ffffffffc0200ebe:	14658593          	addi	a1,a1,326 # ffffffffc0204000 <boot_page_table_sv39>
ffffffffc0200ec2:	00004797          	auipc	a5,0x4
ffffffffc0200ec6:	1ab7b323          	sd	a1,422(a5) # ffffffffc0205068 <satp_virtual>
    satp_physical = PADDR(satp_virtual);
ffffffffc0200eca:	c02007b7          	lui	a5,0xc0200
ffffffffc0200ece:	0af5e363          	bltu	a1,a5,ffffffffc0200f74 <pmm_init+0x1be>
ffffffffc0200ed2:	6090                	ld	a2,0(s1)
}
ffffffffc0200ed4:	7402                	ld	s0,32(sp)
ffffffffc0200ed6:	70a2                	ld	ra,40(sp)
ffffffffc0200ed8:	64e2                	ld	s1,24(sp)
ffffffffc0200eda:	6942                	ld	s2,16(sp)
ffffffffc0200edc:	69a2                	ld	s3,8(sp)
ffffffffc0200ede:	6a02                	ld	s4,0(sp)
    satp_physical = PADDR(satp_virtual);
ffffffffc0200ee0:	40c58633          	sub	a2,a1,a2
ffffffffc0200ee4:	00004797          	auipc	a5,0x4
ffffffffc0200ee8:	16c7be23          	sd	a2,380(a5) # ffffffffc0205060 <satp_physical>
    cprintf("satp virtual address: 0x%016lx\nsatp physical address: 0x%016lx\n", satp_virtual, satp_physical);
ffffffffc0200eec:	00001517          	auipc	a0,0x1
ffffffffc0200ef0:	b0c50513          	addi	a0,a0,-1268 # ffffffffc02019f8 <buddy_pmm_manager+0x110>
}
ffffffffc0200ef4:	6145                	addi	sp,sp,48
    cprintf("satp virtual address: 0x%016lx\nsatp physical address: 0x%016lx\n", satp_virtual, satp_physical);
ffffffffc0200ef6:	a56ff06f          	j	ffffffffc020014c <cprintf>
    npage = maxpa / PGSIZE;
ffffffffc0200efa:	c8000637          	lui	a2,0xc8000
ffffffffc0200efe:	bf25                	j	ffffffffc0200e36 <pmm_init+0x80>
    mem_begin = ROUNDUP(freemem, PGSIZE);
ffffffffc0200f00:	6705                	lui	a4,0x1
ffffffffc0200f02:	177d                	addi	a4,a4,-1
ffffffffc0200f04:	96ba                	add	a3,a3,a4
ffffffffc0200f06:	8efd                	and	a3,a3,a5
    if (PPN(pa) >= npage) {
ffffffffc0200f08:	00c6d793          	srli	a5,a3,0xc
ffffffffc0200f0c:	02c7f063          	bgeu	a5,a2,ffffffffc0200f2c <pmm_init+0x176>
    pmm_manager->init_memmap(base, n);
ffffffffc0200f10:	6010                	ld	a2,0(s0)
    return &pages[PPN(pa) - nbase];
ffffffffc0200f12:	fff80737          	lui	a4,0xfff80
ffffffffc0200f16:	973e                	add	a4,a4,a5
ffffffffc0200f18:	00271793          	slli	a5,a4,0x2
ffffffffc0200f1c:	97ba                	add	a5,a5,a4
ffffffffc0200f1e:	6a18                	ld	a4,16(a2)
        init_memmap(pa2page(mem_begin), (mem_end - mem_begin) / PGSIZE);
ffffffffc0200f20:	8d95                	sub	a1,a1,a3
ffffffffc0200f22:	078e                	slli	a5,a5,0x3
    pmm_manager->init_memmap(base, n);
ffffffffc0200f24:	81b1                	srli	a1,a1,0xc
ffffffffc0200f26:	953e                	add	a0,a0,a5
ffffffffc0200f28:	9702                	jalr	a4
}
ffffffffc0200f2a:	bfbd                	j	ffffffffc0200ea8 <pmm_init+0xf2>
        panic("pa2page called with invalid pa");
ffffffffc0200f2c:	00001617          	auipc	a2,0x1
ffffffffc0200f30:	88460613          	addi	a2,a2,-1916 # ffffffffc02017b0 <etext+0x38e>
ffffffffc0200f34:	06a00593          	li	a1,106
ffffffffc0200f38:	00001517          	auipc	a0,0x1
ffffffffc0200f3c:	89850513          	addi	a0,a0,-1896 # ffffffffc02017d0 <etext+0x3ae>
ffffffffc0200f40:	a82ff0ef          	jal	ra,ffffffffc02001c2 <__panic>
    uintptr_t freemem = PADDR((uintptr_t)pages + sizeof(struct Page) * (npage - nbase));
ffffffffc0200f44:	00001617          	auipc	a2,0x1
ffffffffc0200f48:	a6c60613          	addi	a2,a2,-1428 # ffffffffc02019b0 <buddy_pmm_manager+0xc8>
ffffffffc0200f4c:	05f00593          	li	a1,95
ffffffffc0200f50:	00001517          	auipc	a0,0x1
ffffffffc0200f54:	a0850513          	addi	a0,a0,-1528 # ffffffffc0201958 <buddy_pmm_manager+0x70>
ffffffffc0200f58:	a6aff0ef          	jal	ra,ffffffffc02001c2 <__panic>
        panic("DTB memory info not available");
ffffffffc0200f5c:	00001617          	auipc	a2,0x1
ffffffffc0200f60:	9dc60613          	addi	a2,a2,-1572 # ffffffffc0201938 <buddy_pmm_manager+0x50>
ffffffffc0200f64:	04700593          	li	a1,71
ffffffffc0200f68:	00001517          	auipc	a0,0x1
ffffffffc0200f6c:	9f050513          	addi	a0,a0,-1552 # ffffffffc0201958 <buddy_pmm_manager+0x70>
ffffffffc0200f70:	a52ff0ef          	jal	ra,ffffffffc02001c2 <__panic>
    satp_physical = PADDR(satp_virtual);
ffffffffc0200f74:	86ae                	mv	a3,a1
ffffffffc0200f76:	00001617          	auipc	a2,0x1
ffffffffc0200f7a:	a3a60613          	addi	a2,a2,-1478 # ffffffffc02019b0 <buddy_pmm_manager+0xc8>
ffffffffc0200f7e:	07a00593          	li	a1,122
ffffffffc0200f82:	00001517          	auipc	a0,0x1
ffffffffc0200f86:	9d650513          	addi	a0,a0,-1578 # ffffffffc0201958 <buddy_pmm_manager+0x70>
ffffffffc0200f8a:	a38ff0ef          	jal	ra,ffffffffc02001c2 <__panic>

ffffffffc0200f8e <printnum>:
 * */
static void
printnum(void (*putch)(int, void*), void *putdat,
        unsigned long long num, unsigned base, int width, int padc) {
    unsigned long long result = num;
    unsigned mod = do_div(result, base);
ffffffffc0200f8e:	02069813          	slli	a6,a3,0x20
        unsigned long long num, unsigned base, int width, int padc) {
ffffffffc0200f92:	7179                	addi	sp,sp,-48
    unsigned mod = do_div(result, base);
ffffffffc0200f94:	02085813          	srli	a6,a6,0x20
        unsigned long long num, unsigned base, int width, int padc) {
ffffffffc0200f98:	e052                	sd	s4,0(sp)
    unsigned mod = do_div(result, base);
ffffffffc0200f9a:	03067a33          	remu	s4,a2,a6
        unsigned long long num, unsigned base, int width, int padc) {
ffffffffc0200f9e:	f022                	sd	s0,32(sp)
ffffffffc0200fa0:	ec26                	sd	s1,24(sp)
ffffffffc0200fa2:	e84a                	sd	s2,16(sp)
ffffffffc0200fa4:	f406                	sd	ra,40(sp)
ffffffffc0200fa6:	e44e                	sd	s3,8(sp)
ffffffffc0200fa8:	84aa                	mv	s1,a0
ffffffffc0200faa:	892e                	mv	s2,a1
    // first recursively print all preceding (more significant) digits
    if (num >= base) {
        printnum(putch, putdat, result, base, width - 1, padc);
    } else {
        // print any needed pad characters before first digit
        while (-- width > 0)
ffffffffc0200fac:	fff7041b          	addiw	s0,a4,-1
    unsigned mod = do_div(result, base);
ffffffffc0200fb0:	2a01                	sext.w	s4,s4
    if (num >= base) {
ffffffffc0200fb2:	03067e63          	bgeu	a2,a6,ffffffffc0200fee <printnum+0x60>
ffffffffc0200fb6:	89be                	mv	s3,a5
        while (-- width > 0)
ffffffffc0200fb8:	00805763          	blez	s0,ffffffffc0200fc6 <printnum+0x38>
ffffffffc0200fbc:	347d                	addiw	s0,s0,-1
            putch(padc, putdat);
ffffffffc0200fbe:	85ca                	mv	a1,s2
ffffffffc0200fc0:	854e                	mv	a0,s3
ffffffffc0200fc2:	9482                	jalr	s1
        while (-- width > 0)
ffffffffc0200fc4:	fc65                	bnez	s0,ffffffffc0200fbc <printnum+0x2e>
    }
    // then print this (the least significant) digit
    putch("0123456789abcdef"[mod], putdat);
ffffffffc0200fc6:	1a02                	slli	s4,s4,0x20
ffffffffc0200fc8:	00001797          	auipc	a5,0x1
ffffffffc0200fcc:	a7078793          	addi	a5,a5,-1424 # ffffffffc0201a38 <buddy_pmm_manager+0x150>
ffffffffc0200fd0:	020a5a13          	srli	s4,s4,0x20
ffffffffc0200fd4:	9a3e                	add	s4,s4,a5
}
ffffffffc0200fd6:	7402                	ld	s0,32(sp)
    putch("0123456789abcdef"[mod], putdat);
ffffffffc0200fd8:	000a4503          	lbu	a0,0(s4)
}
ffffffffc0200fdc:	70a2                	ld	ra,40(sp)
ffffffffc0200fde:	69a2                	ld	s3,8(sp)
ffffffffc0200fe0:	6a02                	ld	s4,0(sp)
    putch("0123456789abcdef"[mod], putdat);
ffffffffc0200fe2:	85ca                	mv	a1,s2
ffffffffc0200fe4:	87a6                	mv	a5,s1
}
ffffffffc0200fe6:	6942                	ld	s2,16(sp)
ffffffffc0200fe8:	64e2                	ld	s1,24(sp)
ffffffffc0200fea:	6145                	addi	sp,sp,48
    putch("0123456789abcdef"[mod], putdat);
ffffffffc0200fec:	8782                	jr	a5
        printnum(putch, putdat, result, base, width - 1, padc);
ffffffffc0200fee:	03065633          	divu	a2,a2,a6
ffffffffc0200ff2:	8722                	mv	a4,s0
ffffffffc0200ff4:	f9bff0ef          	jal	ra,ffffffffc0200f8e <printnum>
ffffffffc0200ff8:	b7f9                	j	ffffffffc0200fc6 <printnum+0x38>

ffffffffc0200ffa <vprintfmt>:
 *
 * Call this function if you are already dealing with a va_list.
 * Or you probably want printfmt() instead.
 * */
void
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap) {
ffffffffc0200ffa:	7119                	addi	sp,sp,-128
ffffffffc0200ffc:	f4a6                	sd	s1,104(sp)
ffffffffc0200ffe:	f0ca                	sd	s2,96(sp)
ffffffffc0201000:	ecce                	sd	s3,88(sp)
ffffffffc0201002:	e8d2                	sd	s4,80(sp)
ffffffffc0201004:	e4d6                	sd	s5,72(sp)
ffffffffc0201006:	e0da                	sd	s6,64(sp)
ffffffffc0201008:	fc5e                	sd	s7,56(sp)
ffffffffc020100a:	f06a                	sd	s10,32(sp)
ffffffffc020100c:	fc86                	sd	ra,120(sp)
ffffffffc020100e:	f8a2                	sd	s0,112(sp)
ffffffffc0201010:	f862                	sd	s8,48(sp)
ffffffffc0201012:	f466                	sd	s9,40(sp)
ffffffffc0201014:	ec6e                	sd	s11,24(sp)
ffffffffc0201016:	892a                	mv	s2,a0
ffffffffc0201018:	84ae                	mv	s1,a1
ffffffffc020101a:	8d32                	mv	s10,a2
ffffffffc020101c:	8a36                	mv	s4,a3
    register int ch, err;
    unsigned long long num;
    int base, width, precision, lflag, altflag;

    while (1) {
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc020101e:	02500993          	li	s3,37
            putch(ch, putdat);
        }

        // Process a %-escape sequence
        char padc = ' ';
        width = precision = -1;
ffffffffc0201022:	5b7d                	li	s6,-1
ffffffffc0201024:	00001a97          	auipc	s5,0x1
ffffffffc0201028:	a48a8a93          	addi	s5,s5,-1464 # ffffffffc0201a6c <buddy_pmm_manager+0x184>
        case 'e':
            err = va_arg(ap, int);
            if (err < 0) {
                err = -err;
            }
            if (err > MAXERROR || (p = error_string[err]) == NULL) {
ffffffffc020102c:	00001b97          	auipc	s7,0x1
ffffffffc0201030:	c1cb8b93          	addi	s7,s7,-996 # ffffffffc0201c48 <error_string>
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc0201034:	000d4503          	lbu	a0,0(s10)
ffffffffc0201038:	001d0413          	addi	s0,s10,1
ffffffffc020103c:	01350a63          	beq	a0,s3,ffffffffc0201050 <vprintfmt+0x56>
            if (ch == '\0') {
ffffffffc0201040:	c121                	beqz	a0,ffffffffc0201080 <vprintfmt+0x86>
            putch(ch, putdat);
ffffffffc0201042:	85a6                	mv	a1,s1
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc0201044:	0405                	addi	s0,s0,1
            putch(ch, putdat);
ffffffffc0201046:	9902                	jalr	s2
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc0201048:	fff44503          	lbu	a0,-1(s0)
ffffffffc020104c:	ff351ae3          	bne	a0,s3,ffffffffc0201040 <vprintfmt+0x46>
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0201050:	00044603          	lbu	a2,0(s0)
        char padc = ' ';
ffffffffc0201054:	02000793          	li	a5,32
        lflag = altflag = 0;
ffffffffc0201058:	4c81                	li	s9,0
ffffffffc020105a:	4881                	li	a7,0
        width = precision = -1;
ffffffffc020105c:	5c7d                	li	s8,-1
ffffffffc020105e:	5dfd                	li	s11,-1
ffffffffc0201060:	05500513          	li	a0,85
                if (ch < '0' || ch > '9') {
ffffffffc0201064:	4825                	li	a6,9
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0201066:	fdd6059b          	addiw	a1,a2,-35
ffffffffc020106a:	0ff5f593          	andi	a1,a1,255
ffffffffc020106e:	00140d13          	addi	s10,s0,1
ffffffffc0201072:	04b56263          	bltu	a0,a1,ffffffffc02010b6 <vprintfmt+0xbc>
ffffffffc0201076:	058a                	slli	a1,a1,0x2
ffffffffc0201078:	95d6                	add	a1,a1,s5
ffffffffc020107a:	4194                	lw	a3,0(a1)
ffffffffc020107c:	96d6                	add	a3,a3,s5
ffffffffc020107e:	8682                	jr	a3
            for (fmt --; fmt[-1] != '%'; fmt --)
                /* do nothing */;
            break;
        }
    }
}
ffffffffc0201080:	70e6                	ld	ra,120(sp)
ffffffffc0201082:	7446                	ld	s0,112(sp)
ffffffffc0201084:	74a6                	ld	s1,104(sp)
ffffffffc0201086:	7906                	ld	s2,96(sp)
ffffffffc0201088:	69e6                	ld	s3,88(sp)
ffffffffc020108a:	6a46                	ld	s4,80(sp)
ffffffffc020108c:	6aa6                	ld	s5,72(sp)
ffffffffc020108e:	6b06                	ld	s6,64(sp)
ffffffffc0201090:	7be2                	ld	s7,56(sp)
ffffffffc0201092:	7c42                	ld	s8,48(sp)
ffffffffc0201094:	7ca2                	ld	s9,40(sp)
ffffffffc0201096:	7d02                	ld	s10,32(sp)
ffffffffc0201098:	6de2                	ld	s11,24(sp)
ffffffffc020109a:	6109                	addi	sp,sp,128
ffffffffc020109c:	8082                	ret
            padc = '0';
ffffffffc020109e:	87b2                	mv	a5,a2
            goto reswitch;
ffffffffc02010a0:	00144603          	lbu	a2,1(s0)
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc02010a4:	846a                	mv	s0,s10
ffffffffc02010a6:	00140d13          	addi	s10,s0,1
ffffffffc02010aa:	fdd6059b          	addiw	a1,a2,-35
ffffffffc02010ae:	0ff5f593          	andi	a1,a1,255
ffffffffc02010b2:	fcb572e3          	bgeu	a0,a1,ffffffffc0201076 <vprintfmt+0x7c>
            putch('%', putdat);
ffffffffc02010b6:	85a6                	mv	a1,s1
ffffffffc02010b8:	02500513          	li	a0,37
ffffffffc02010bc:	9902                	jalr	s2
            for (fmt --; fmt[-1] != '%'; fmt --)
ffffffffc02010be:	fff44783          	lbu	a5,-1(s0)
ffffffffc02010c2:	8d22                	mv	s10,s0
ffffffffc02010c4:	f73788e3          	beq	a5,s3,ffffffffc0201034 <vprintfmt+0x3a>
ffffffffc02010c8:	ffed4783          	lbu	a5,-2(s10)
ffffffffc02010cc:	1d7d                	addi	s10,s10,-1
ffffffffc02010ce:	ff379de3          	bne	a5,s3,ffffffffc02010c8 <vprintfmt+0xce>
ffffffffc02010d2:	b78d                	j	ffffffffc0201034 <vprintfmt+0x3a>
                precision = precision * 10 + ch - '0';
ffffffffc02010d4:	fd060c1b          	addiw	s8,a2,-48
                ch = *fmt;
ffffffffc02010d8:	00144603          	lbu	a2,1(s0)
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc02010dc:	846a                	mv	s0,s10
                if (ch < '0' || ch > '9') {
ffffffffc02010de:	fd06069b          	addiw	a3,a2,-48
                ch = *fmt;
ffffffffc02010e2:	0006059b          	sext.w	a1,a2
                if (ch < '0' || ch > '9') {
ffffffffc02010e6:	02d86463          	bltu	a6,a3,ffffffffc020110e <vprintfmt+0x114>
                ch = *fmt;
ffffffffc02010ea:	00144603          	lbu	a2,1(s0)
                precision = precision * 10 + ch - '0';
ffffffffc02010ee:	002c169b          	slliw	a3,s8,0x2
ffffffffc02010f2:	0186873b          	addw	a4,a3,s8
ffffffffc02010f6:	0017171b          	slliw	a4,a4,0x1
ffffffffc02010fa:	9f2d                	addw	a4,a4,a1
                if (ch < '0' || ch > '9') {
ffffffffc02010fc:	fd06069b          	addiw	a3,a2,-48
            for (precision = 0; ; ++ fmt) {
ffffffffc0201100:	0405                	addi	s0,s0,1
                precision = precision * 10 + ch - '0';
ffffffffc0201102:	fd070c1b          	addiw	s8,a4,-48
                ch = *fmt;
ffffffffc0201106:	0006059b          	sext.w	a1,a2
                if (ch < '0' || ch > '9') {
ffffffffc020110a:	fed870e3          	bgeu	a6,a3,ffffffffc02010ea <vprintfmt+0xf0>
            if (width < 0)
ffffffffc020110e:	f40ddce3          	bgez	s11,ffffffffc0201066 <vprintfmt+0x6c>
                width = precision, precision = -1;
ffffffffc0201112:	8de2                	mv	s11,s8
ffffffffc0201114:	5c7d                	li	s8,-1
ffffffffc0201116:	bf81                	j	ffffffffc0201066 <vprintfmt+0x6c>
            if (width < 0)
ffffffffc0201118:	fffdc693          	not	a3,s11
ffffffffc020111c:	96fd                	srai	a3,a3,0x3f
ffffffffc020111e:	00ddfdb3          	and	s11,s11,a3
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0201122:	00144603          	lbu	a2,1(s0)
ffffffffc0201126:	2d81                	sext.w	s11,s11
ffffffffc0201128:	846a                	mv	s0,s10
            goto reswitch;
ffffffffc020112a:	bf35                	j	ffffffffc0201066 <vprintfmt+0x6c>
            precision = va_arg(ap, int);
ffffffffc020112c:	000a2c03          	lw	s8,0(s4)
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0201130:	00144603          	lbu	a2,1(s0)
            precision = va_arg(ap, int);
ffffffffc0201134:	0a21                	addi	s4,s4,8
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0201136:	846a                	mv	s0,s10
            goto process_precision;
ffffffffc0201138:	bfd9                	j	ffffffffc020110e <vprintfmt+0x114>
    if (lflag >= 2) {
ffffffffc020113a:	4705                	li	a4,1
            precision = va_arg(ap, int);
ffffffffc020113c:	008a0593          	addi	a1,s4,8
    if (lflag >= 2) {
ffffffffc0201140:	01174463          	blt	a4,a7,ffffffffc0201148 <vprintfmt+0x14e>
    else if (lflag) {
ffffffffc0201144:	1a088e63          	beqz	a7,ffffffffc0201300 <vprintfmt+0x306>
        return va_arg(*ap, unsigned long);
ffffffffc0201148:	000a3603          	ld	a2,0(s4)
ffffffffc020114c:	46c1                	li	a3,16
ffffffffc020114e:	8a2e                	mv	s4,a1
            printnum(putch, putdat, num, base, width, padc);
ffffffffc0201150:	2781                	sext.w	a5,a5
ffffffffc0201152:	876e                	mv	a4,s11
ffffffffc0201154:	85a6                	mv	a1,s1
ffffffffc0201156:	854a                	mv	a0,s2
ffffffffc0201158:	e37ff0ef          	jal	ra,ffffffffc0200f8e <printnum>
            break;
ffffffffc020115c:	bde1                	j	ffffffffc0201034 <vprintfmt+0x3a>
            putch(va_arg(ap, int), putdat);
ffffffffc020115e:	000a2503          	lw	a0,0(s4)
ffffffffc0201162:	85a6                	mv	a1,s1
ffffffffc0201164:	0a21                	addi	s4,s4,8
ffffffffc0201166:	9902                	jalr	s2
            break;
ffffffffc0201168:	b5f1                	j	ffffffffc0201034 <vprintfmt+0x3a>
    if (lflag >= 2) {
ffffffffc020116a:	4705                	li	a4,1
            precision = va_arg(ap, int);
ffffffffc020116c:	008a0593          	addi	a1,s4,8
    if (lflag >= 2) {
ffffffffc0201170:	01174463          	blt	a4,a7,ffffffffc0201178 <vprintfmt+0x17e>
    else if (lflag) {
ffffffffc0201174:	18088163          	beqz	a7,ffffffffc02012f6 <vprintfmt+0x2fc>
        return va_arg(*ap, unsigned long);
ffffffffc0201178:	000a3603          	ld	a2,0(s4)
ffffffffc020117c:	46a9                	li	a3,10
ffffffffc020117e:	8a2e                	mv	s4,a1
ffffffffc0201180:	bfc1                	j	ffffffffc0201150 <vprintfmt+0x156>
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0201182:	00144603          	lbu	a2,1(s0)
            altflag = 1;
ffffffffc0201186:	4c85                	li	s9,1
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0201188:	846a                	mv	s0,s10
            goto reswitch;
ffffffffc020118a:	bdf1                	j	ffffffffc0201066 <vprintfmt+0x6c>
            putch(ch, putdat);
ffffffffc020118c:	85a6                	mv	a1,s1
ffffffffc020118e:	02500513          	li	a0,37
ffffffffc0201192:	9902                	jalr	s2
            break;
ffffffffc0201194:	b545                	j	ffffffffc0201034 <vprintfmt+0x3a>
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0201196:	00144603          	lbu	a2,1(s0)
            lflag ++;
ffffffffc020119a:	2885                	addiw	a7,a7,1
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc020119c:	846a                	mv	s0,s10
            goto reswitch;
ffffffffc020119e:	b5e1                	j	ffffffffc0201066 <vprintfmt+0x6c>
    if (lflag >= 2) {
ffffffffc02011a0:	4705                	li	a4,1
            precision = va_arg(ap, int);
ffffffffc02011a2:	008a0593          	addi	a1,s4,8
    if (lflag >= 2) {
ffffffffc02011a6:	01174463          	blt	a4,a7,ffffffffc02011ae <vprintfmt+0x1b4>
    else if (lflag) {
ffffffffc02011aa:	14088163          	beqz	a7,ffffffffc02012ec <vprintfmt+0x2f2>
        return va_arg(*ap, unsigned long);
ffffffffc02011ae:	000a3603          	ld	a2,0(s4)
ffffffffc02011b2:	46a1                	li	a3,8
ffffffffc02011b4:	8a2e                	mv	s4,a1
ffffffffc02011b6:	bf69                	j	ffffffffc0201150 <vprintfmt+0x156>
            putch('0', putdat);
ffffffffc02011b8:	03000513          	li	a0,48
ffffffffc02011bc:	85a6                	mv	a1,s1
ffffffffc02011be:	e03e                	sd	a5,0(sp)
ffffffffc02011c0:	9902                	jalr	s2
            putch('x', putdat);
ffffffffc02011c2:	85a6                	mv	a1,s1
ffffffffc02011c4:	07800513          	li	a0,120
ffffffffc02011c8:	9902                	jalr	s2
            num = (unsigned long long)(uintptr_t)va_arg(ap, void *);
ffffffffc02011ca:	0a21                	addi	s4,s4,8
            goto number;
ffffffffc02011cc:	6782                	ld	a5,0(sp)
ffffffffc02011ce:	46c1                	li	a3,16
            num = (unsigned long long)(uintptr_t)va_arg(ap, void *);
ffffffffc02011d0:	ff8a3603          	ld	a2,-8(s4)
            goto number;
ffffffffc02011d4:	bfb5                	j	ffffffffc0201150 <vprintfmt+0x156>
            if ((p = va_arg(ap, char *)) == NULL) {
ffffffffc02011d6:	000a3403          	ld	s0,0(s4)
ffffffffc02011da:	008a0713          	addi	a4,s4,8
ffffffffc02011de:	e03a                	sd	a4,0(sp)
ffffffffc02011e0:	14040263          	beqz	s0,ffffffffc0201324 <vprintfmt+0x32a>
            if (width > 0 && padc != '-') {
ffffffffc02011e4:	0fb05763          	blez	s11,ffffffffc02012d2 <vprintfmt+0x2d8>
ffffffffc02011e8:	02d00693          	li	a3,45
ffffffffc02011ec:	0cd79163          	bne	a5,a3,ffffffffc02012ae <vprintfmt+0x2b4>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc02011f0:	00044783          	lbu	a5,0(s0)
ffffffffc02011f4:	0007851b          	sext.w	a0,a5
ffffffffc02011f8:	cf85                	beqz	a5,ffffffffc0201230 <vprintfmt+0x236>
ffffffffc02011fa:	00140a13          	addi	s4,s0,1
                if (altflag && (ch < ' ' || ch > '~')) {
ffffffffc02011fe:	05e00413          	li	s0,94
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc0201202:	000c4563          	bltz	s8,ffffffffc020120c <vprintfmt+0x212>
ffffffffc0201206:	3c7d                	addiw	s8,s8,-1
ffffffffc0201208:	036c0263          	beq	s8,s6,ffffffffc020122c <vprintfmt+0x232>
                    putch('?', putdat);
ffffffffc020120c:	85a6                	mv	a1,s1
                if (altflag && (ch < ' ' || ch > '~')) {
ffffffffc020120e:	0e0c8e63          	beqz	s9,ffffffffc020130a <vprintfmt+0x310>
ffffffffc0201212:	3781                	addiw	a5,a5,-32
ffffffffc0201214:	0ef47b63          	bgeu	s0,a5,ffffffffc020130a <vprintfmt+0x310>
                    putch('?', putdat);
ffffffffc0201218:	03f00513          	li	a0,63
ffffffffc020121c:	9902                	jalr	s2
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc020121e:	000a4783          	lbu	a5,0(s4)
ffffffffc0201222:	3dfd                	addiw	s11,s11,-1
ffffffffc0201224:	0a05                	addi	s4,s4,1
ffffffffc0201226:	0007851b          	sext.w	a0,a5
ffffffffc020122a:	ffe1                	bnez	a5,ffffffffc0201202 <vprintfmt+0x208>
            for (; width > 0; width --) {
ffffffffc020122c:	01b05963          	blez	s11,ffffffffc020123e <vprintfmt+0x244>
ffffffffc0201230:	3dfd                	addiw	s11,s11,-1
                putch(' ', putdat);
ffffffffc0201232:	85a6                	mv	a1,s1
ffffffffc0201234:	02000513          	li	a0,32
ffffffffc0201238:	9902                	jalr	s2
            for (; width > 0; width --) {
ffffffffc020123a:	fe0d9be3          	bnez	s11,ffffffffc0201230 <vprintfmt+0x236>
            if ((p = va_arg(ap, char *)) == NULL) {
ffffffffc020123e:	6a02                	ld	s4,0(sp)
ffffffffc0201240:	bbd5                	j	ffffffffc0201034 <vprintfmt+0x3a>
    if (lflag >= 2) {
ffffffffc0201242:	4705                	li	a4,1
            precision = va_arg(ap, int);
ffffffffc0201244:	008a0c93          	addi	s9,s4,8
    if (lflag >= 2) {
ffffffffc0201248:	01174463          	blt	a4,a7,ffffffffc0201250 <vprintfmt+0x256>
    else if (lflag) {
ffffffffc020124c:	08088d63          	beqz	a7,ffffffffc02012e6 <vprintfmt+0x2ec>
        return va_arg(*ap, long);
ffffffffc0201250:	000a3403          	ld	s0,0(s4)
            if ((long long)num < 0) {
ffffffffc0201254:	0a044d63          	bltz	s0,ffffffffc020130e <vprintfmt+0x314>
            num = getint(&ap, lflag);
ffffffffc0201258:	8622                	mv	a2,s0
ffffffffc020125a:	8a66                	mv	s4,s9
ffffffffc020125c:	46a9                	li	a3,10
ffffffffc020125e:	bdcd                	j	ffffffffc0201150 <vprintfmt+0x156>
            err = va_arg(ap, int);
ffffffffc0201260:	000a2783          	lw	a5,0(s4)
            if (err > MAXERROR || (p = error_string[err]) == NULL) {
ffffffffc0201264:	4719                	li	a4,6
            err = va_arg(ap, int);
ffffffffc0201266:	0a21                	addi	s4,s4,8
            if (err < 0) {
ffffffffc0201268:	41f7d69b          	sraiw	a3,a5,0x1f
ffffffffc020126c:	8fb5                	xor	a5,a5,a3
ffffffffc020126e:	40d786bb          	subw	a3,a5,a3
            if (err > MAXERROR || (p = error_string[err]) == NULL) {
ffffffffc0201272:	02d74163          	blt	a4,a3,ffffffffc0201294 <vprintfmt+0x29a>
ffffffffc0201276:	00369793          	slli	a5,a3,0x3
ffffffffc020127a:	97de                	add	a5,a5,s7
ffffffffc020127c:	639c                	ld	a5,0(a5)
ffffffffc020127e:	cb99                	beqz	a5,ffffffffc0201294 <vprintfmt+0x29a>
                printfmt(putch, putdat, "%s", p);
ffffffffc0201280:	86be                	mv	a3,a5
ffffffffc0201282:	00000617          	auipc	a2,0x0
ffffffffc0201286:	7e660613          	addi	a2,a2,2022 # ffffffffc0201a68 <buddy_pmm_manager+0x180>
ffffffffc020128a:	85a6                	mv	a1,s1
ffffffffc020128c:	854a                	mv	a0,s2
ffffffffc020128e:	0ce000ef          	jal	ra,ffffffffc020135c <printfmt>
ffffffffc0201292:	b34d                	j	ffffffffc0201034 <vprintfmt+0x3a>
                printfmt(putch, putdat, "error %d", err);
ffffffffc0201294:	00000617          	auipc	a2,0x0
ffffffffc0201298:	7c460613          	addi	a2,a2,1988 # ffffffffc0201a58 <buddy_pmm_manager+0x170>
ffffffffc020129c:	85a6                	mv	a1,s1
ffffffffc020129e:	854a                	mv	a0,s2
ffffffffc02012a0:	0bc000ef          	jal	ra,ffffffffc020135c <printfmt>
ffffffffc02012a4:	bb41                	j	ffffffffc0201034 <vprintfmt+0x3a>
                p = "(null)";
ffffffffc02012a6:	00000417          	auipc	s0,0x0
ffffffffc02012aa:	7aa40413          	addi	s0,s0,1962 # ffffffffc0201a50 <buddy_pmm_manager+0x168>
                for (width -= strnlen(p, precision); width > 0; width --) {
ffffffffc02012ae:	85e2                	mv	a1,s8
ffffffffc02012b0:	8522                	mv	a0,s0
ffffffffc02012b2:	e43e                	sd	a5,8(sp)
ffffffffc02012b4:	0fc000ef          	jal	ra,ffffffffc02013b0 <strnlen>
ffffffffc02012b8:	40ad8dbb          	subw	s11,s11,a0
ffffffffc02012bc:	01b05b63          	blez	s11,ffffffffc02012d2 <vprintfmt+0x2d8>
                    putch(padc, putdat);
ffffffffc02012c0:	67a2                	ld	a5,8(sp)
ffffffffc02012c2:	00078a1b          	sext.w	s4,a5
                for (width -= strnlen(p, precision); width > 0; width --) {
ffffffffc02012c6:	3dfd                	addiw	s11,s11,-1
                    putch(padc, putdat);
ffffffffc02012c8:	85a6                	mv	a1,s1
ffffffffc02012ca:	8552                	mv	a0,s4
ffffffffc02012cc:	9902                	jalr	s2
                for (width -= strnlen(p, precision); width > 0; width --) {
ffffffffc02012ce:	fe0d9ce3          	bnez	s11,ffffffffc02012c6 <vprintfmt+0x2cc>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc02012d2:	00044783          	lbu	a5,0(s0)
ffffffffc02012d6:	00140a13          	addi	s4,s0,1
ffffffffc02012da:	0007851b          	sext.w	a0,a5
ffffffffc02012de:	d3a5                	beqz	a5,ffffffffc020123e <vprintfmt+0x244>
                if (altflag && (ch < ' ' || ch > '~')) {
ffffffffc02012e0:	05e00413          	li	s0,94
ffffffffc02012e4:	bf39                	j	ffffffffc0201202 <vprintfmt+0x208>
        return va_arg(*ap, int);
ffffffffc02012e6:	000a2403          	lw	s0,0(s4)
ffffffffc02012ea:	b7ad                	j	ffffffffc0201254 <vprintfmt+0x25a>
        return va_arg(*ap, unsigned int);
ffffffffc02012ec:	000a6603          	lwu	a2,0(s4)
ffffffffc02012f0:	46a1                	li	a3,8
ffffffffc02012f2:	8a2e                	mv	s4,a1
ffffffffc02012f4:	bdb1                	j	ffffffffc0201150 <vprintfmt+0x156>
ffffffffc02012f6:	000a6603          	lwu	a2,0(s4)
ffffffffc02012fa:	46a9                	li	a3,10
ffffffffc02012fc:	8a2e                	mv	s4,a1
ffffffffc02012fe:	bd89                	j	ffffffffc0201150 <vprintfmt+0x156>
ffffffffc0201300:	000a6603          	lwu	a2,0(s4)
ffffffffc0201304:	46c1                	li	a3,16
ffffffffc0201306:	8a2e                	mv	s4,a1
ffffffffc0201308:	b5a1                	j	ffffffffc0201150 <vprintfmt+0x156>
                    putch(ch, putdat);
ffffffffc020130a:	9902                	jalr	s2
ffffffffc020130c:	bf09                	j	ffffffffc020121e <vprintfmt+0x224>
                putch('-', putdat);
ffffffffc020130e:	85a6                	mv	a1,s1
ffffffffc0201310:	02d00513          	li	a0,45
ffffffffc0201314:	e03e                	sd	a5,0(sp)
ffffffffc0201316:	9902                	jalr	s2
                num = -(long long)num;
ffffffffc0201318:	6782                	ld	a5,0(sp)
ffffffffc020131a:	8a66                	mv	s4,s9
ffffffffc020131c:	40800633          	neg	a2,s0
ffffffffc0201320:	46a9                	li	a3,10
ffffffffc0201322:	b53d                	j	ffffffffc0201150 <vprintfmt+0x156>
            if (width > 0 && padc != '-') {
ffffffffc0201324:	03b05163          	blez	s11,ffffffffc0201346 <vprintfmt+0x34c>
ffffffffc0201328:	02d00693          	li	a3,45
ffffffffc020132c:	f6d79de3          	bne	a5,a3,ffffffffc02012a6 <vprintfmt+0x2ac>
                p = "(null)";
ffffffffc0201330:	00000417          	auipc	s0,0x0
ffffffffc0201334:	72040413          	addi	s0,s0,1824 # ffffffffc0201a50 <buddy_pmm_manager+0x168>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc0201338:	02800793          	li	a5,40
ffffffffc020133c:	02800513          	li	a0,40
ffffffffc0201340:	00140a13          	addi	s4,s0,1
ffffffffc0201344:	bd6d                	j	ffffffffc02011fe <vprintfmt+0x204>
ffffffffc0201346:	00000a17          	auipc	s4,0x0
ffffffffc020134a:	70ba0a13          	addi	s4,s4,1803 # ffffffffc0201a51 <buddy_pmm_manager+0x169>
ffffffffc020134e:	02800513          	li	a0,40
ffffffffc0201352:	02800793          	li	a5,40
                if (altflag && (ch < ' ' || ch > '~')) {
ffffffffc0201356:	05e00413          	li	s0,94
ffffffffc020135a:	b565                	j	ffffffffc0201202 <vprintfmt+0x208>

ffffffffc020135c <printfmt>:
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
ffffffffc020135c:	715d                	addi	sp,sp,-80
    va_start(ap, fmt);
ffffffffc020135e:	02810313          	addi	t1,sp,40
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
ffffffffc0201362:	f436                	sd	a3,40(sp)
    vprintfmt(putch, putdat, fmt, ap);
ffffffffc0201364:	869a                	mv	a3,t1
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
ffffffffc0201366:	ec06                	sd	ra,24(sp)
ffffffffc0201368:	f83a                	sd	a4,48(sp)
ffffffffc020136a:	fc3e                	sd	a5,56(sp)
ffffffffc020136c:	e0c2                	sd	a6,64(sp)
ffffffffc020136e:	e4c6                	sd	a7,72(sp)
    va_start(ap, fmt);
ffffffffc0201370:	e41a                	sd	t1,8(sp)
    vprintfmt(putch, putdat, fmt, ap);
ffffffffc0201372:	c89ff0ef          	jal	ra,ffffffffc0200ffa <vprintfmt>
}
ffffffffc0201376:	60e2                	ld	ra,24(sp)
ffffffffc0201378:	6161                	addi	sp,sp,80
ffffffffc020137a:	8082                	ret

ffffffffc020137c <sbi_console_putchar>:
uint64_t SBI_REMOTE_SFENCE_VMA_ASID = 7;
uint64_t SBI_SHUTDOWN = 8;

uint64_t sbi_call(uint64_t sbi_type, uint64_t arg0, uint64_t arg1, uint64_t arg2) {
    uint64_t ret_val;
    __asm__ volatile (
ffffffffc020137c:	4781                	li	a5,0
ffffffffc020137e:	00004717          	auipc	a4,0x4
ffffffffc0201382:	c9273703          	ld	a4,-878(a4) # ffffffffc0205010 <SBI_CONSOLE_PUTCHAR>
ffffffffc0201386:	88ba                	mv	a7,a4
ffffffffc0201388:	852a                	mv	a0,a0
ffffffffc020138a:	85be                	mv	a1,a5
ffffffffc020138c:	863e                	mv	a2,a5
ffffffffc020138e:	00000073          	ecall
ffffffffc0201392:	87aa                	mv	a5,a0
    return ret_val;
}

void sbi_console_putchar(unsigned char ch) {
    sbi_call(SBI_CONSOLE_PUTCHAR, ch, 0, 0);
}
ffffffffc0201394:	8082                	ret

ffffffffc0201396 <strlen>:
 * The strlen() function returns the length of string @s.
 * */
size_t
strlen(const char *s) {
    size_t cnt = 0;
    while (*s ++ != '\0') {
ffffffffc0201396:	00054783          	lbu	a5,0(a0)
strlen(const char *s) {
ffffffffc020139a:	872a                	mv	a4,a0
    size_t cnt = 0;
ffffffffc020139c:	4501                	li	a0,0
    while (*s ++ != '\0') {
ffffffffc020139e:	cb81                	beqz	a5,ffffffffc02013ae <strlen+0x18>
        cnt ++;
ffffffffc02013a0:	0505                	addi	a0,a0,1
    while (*s ++ != '\0') {
ffffffffc02013a2:	00a707b3          	add	a5,a4,a0
ffffffffc02013a6:	0007c783          	lbu	a5,0(a5)
ffffffffc02013aa:	fbfd                	bnez	a5,ffffffffc02013a0 <strlen+0xa>
ffffffffc02013ac:	8082                	ret
    }
    return cnt;
}
ffffffffc02013ae:	8082                	ret

ffffffffc02013b0 <strnlen>:
 * @len if there is no '\0' character among the first @len characters
 * pointed by @s.
 * */
size_t
strnlen(const char *s, size_t len) {
    size_t cnt = 0;
ffffffffc02013b0:	4781                	li	a5,0
    while (cnt < len && *s ++ != '\0') {
ffffffffc02013b2:	e589                	bnez	a1,ffffffffc02013bc <strnlen+0xc>
ffffffffc02013b4:	a811                	j	ffffffffc02013c8 <strnlen+0x18>
        cnt ++;
ffffffffc02013b6:	0785                	addi	a5,a5,1
    while (cnt < len && *s ++ != '\0') {
ffffffffc02013b8:	00f58863          	beq	a1,a5,ffffffffc02013c8 <strnlen+0x18>
ffffffffc02013bc:	00f50733          	add	a4,a0,a5
ffffffffc02013c0:	00074703          	lbu	a4,0(a4)
ffffffffc02013c4:	fb6d                	bnez	a4,ffffffffc02013b6 <strnlen+0x6>
ffffffffc02013c6:	85be                	mv	a1,a5
    }
    return cnt;
}
ffffffffc02013c8:	852e                	mv	a0,a1
ffffffffc02013ca:	8082                	ret

ffffffffc02013cc <strcmp>:
int
strcmp(const char *s1, const char *s2) {
#ifdef __HAVE_ARCH_STRCMP
    return __strcmp(s1, s2);
#else
    while (*s1 != '\0' && *s1 == *s2) {
ffffffffc02013cc:	00054783          	lbu	a5,0(a0)
        s1 ++, s2 ++;
    }
    return (int)((unsigned char)*s1 - (unsigned char)*s2);
ffffffffc02013d0:	0005c703          	lbu	a4,0(a1)
    while (*s1 != '\0' && *s1 == *s2) {
ffffffffc02013d4:	cb89                	beqz	a5,ffffffffc02013e6 <strcmp+0x1a>
        s1 ++, s2 ++;
ffffffffc02013d6:	0505                	addi	a0,a0,1
ffffffffc02013d8:	0585                	addi	a1,a1,1
    while (*s1 != '\0' && *s1 == *s2) {
ffffffffc02013da:	fee789e3          	beq	a5,a4,ffffffffc02013cc <strcmp>
    return (int)((unsigned char)*s1 - (unsigned char)*s2);
ffffffffc02013de:	0007851b          	sext.w	a0,a5
#endif /* __HAVE_ARCH_STRCMP */
}
ffffffffc02013e2:	9d19                	subw	a0,a0,a4
ffffffffc02013e4:	8082                	ret
ffffffffc02013e6:	4501                	li	a0,0
ffffffffc02013e8:	bfed                	j	ffffffffc02013e2 <strcmp+0x16>

ffffffffc02013ea <strncmp>:
 * the characters differ, until a terminating null-character is reached, or
 * until @n characters match in both strings, whichever happens first.
 * */
int
strncmp(const char *s1, const char *s2, size_t n) {
    while (n > 0 && *s1 != '\0' && *s1 == *s2) {
ffffffffc02013ea:	c20d                	beqz	a2,ffffffffc020140c <strncmp+0x22>
ffffffffc02013ec:	962e                	add	a2,a2,a1
ffffffffc02013ee:	a031                	j	ffffffffc02013fa <strncmp+0x10>
        n --, s1 ++, s2 ++;
ffffffffc02013f0:	0505                	addi	a0,a0,1
    while (n > 0 && *s1 != '\0' && *s1 == *s2) {
ffffffffc02013f2:	00e79a63          	bne	a5,a4,ffffffffc0201406 <strncmp+0x1c>
ffffffffc02013f6:	00b60b63          	beq	a2,a1,ffffffffc020140c <strncmp+0x22>
ffffffffc02013fa:	00054783          	lbu	a5,0(a0)
        n --, s1 ++, s2 ++;
ffffffffc02013fe:	0585                	addi	a1,a1,1
    while (n > 0 && *s1 != '\0' && *s1 == *s2) {
ffffffffc0201400:	fff5c703          	lbu	a4,-1(a1)
ffffffffc0201404:	f7f5                	bnez	a5,ffffffffc02013f0 <strncmp+0x6>
    }
    return (n == 0) ? 0 : (int)((unsigned char)*s1 - (unsigned char)*s2);
ffffffffc0201406:	40e7853b          	subw	a0,a5,a4
}
ffffffffc020140a:	8082                	ret
    return (n == 0) ? 0 : (int)((unsigned char)*s1 - (unsigned char)*s2);
ffffffffc020140c:	4501                	li	a0,0
ffffffffc020140e:	8082                	ret

ffffffffc0201410 <memset>:
memset(void *s, char c, size_t n) {
#ifdef __HAVE_ARCH_MEMSET
    return __memset(s, c, n);
#else
    char *p = s;
    while (n -- > 0) {
ffffffffc0201410:	ca01                	beqz	a2,ffffffffc0201420 <memset+0x10>
ffffffffc0201412:	962a                	add	a2,a2,a0
    char *p = s;
ffffffffc0201414:	87aa                	mv	a5,a0
        *p ++ = c;
ffffffffc0201416:	0785                	addi	a5,a5,1
ffffffffc0201418:	feb78fa3          	sb	a1,-1(a5)
    while (n -- > 0) {
ffffffffc020141c:	fec79de3          	bne	a5,a2,ffffffffc0201416 <memset+0x6>
    }
    return s;
#endif /* __HAVE_ARCH_MEMSET */
}
ffffffffc0201420:	8082                	ret
