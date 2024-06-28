
kernel/kernel:     file format elf64-littleriscv


Disassembly of section .text:

0000000080000000 <_entry>:
    80000000:	00009117          	auipc	sp,0x9
    80000004:	8b013103          	ld	sp,-1872(sp) # 800088b0 <_GLOBAL_OFFSET_TABLE_+0x8>
    80000008:	6505                	lui	a0,0x1
    8000000a:	f14025f3          	csrr	a1,mhartid
    8000000e:	0585                	addi	a1,a1,1
    80000010:	02b50533          	mul	a0,a0,a1
    80000014:	912a                	add	sp,sp,a0
    80000016:	076000ef          	jal	ra,8000008c <start>

000000008000001a <spin>:
    8000001a:	a001                	j	8000001a <spin>

000000008000001c <timerinit>:
// at timervec in kernelvec.S,
// which turns them into software interrupts for
// devintr() in trap.c.
void
timerinit()
{
    8000001c:	1141                	addi	sp,sp,-16
    8000001e:	e422                	sd	s0,8(sp)
    80000020:	0800                	addi	s0,sp,16
// which hart (core) is this?
static inline uint64
r_mhartid()
{
  uint64 x;
  asm volatile("csrr %0, mhartid" : "=r" (x) );
    80000022:	f14027f3          	csrr	a5,mhartid
  // each CPU has a separate source of timer interrupts.
  int id = r_mhartid();
    80000026:	0007859b          	sext.w	a1,a5

  // ask the CLINT for a timer interrupt.
  int interval = 1000000; // cycles; about 1/10th second in qemu.
  *(uint64*)CLINT_MTIMECMP(id) = *(uint64*)CLINT_MTIME + interval;
    8000002a:	0037979b          	slliw	a5,a5,0x3
    8000002e:	02004737          	lui	a4,0x2004
    80000032:	97ba                	add	a5,a5,a4
    80000034:	0200c737          	lui	a4,0x200c
    80000038:	ff873703          	ld	a4,-8(a4) # 200bff8 <_entry-0x7dff4008>
    8000003c:	000f4637          	lui	a2,0xf4
    80000040:	24060613          	addi	a2,a2,576 # f4240 <_entry-0x7ff0bdc0>
    80000044:	9732                	add	a4,a4,a2
    80000046:	e398                	sd	a4,0(a5)

  // prepare information in scratch[] for timervec.
  // scratch[0..2] : space for timervec to save registers.
  // scratch[3] : address of CLINT MTIMECMP register.
  // scratch[4] : desired interval (in cycles) between timer interrupts.
  uint64 *scratch = &timer_scratch[id][0];
    80000048:	00259693          	slli	a3,a1,0x2
    8000004c:	96ae                	add	a3,a3,a1
    8000004e:	068e                	slli	a3,a3,0x3
    80000050:	00009717          	auipc	a4,0x9
    80000054:	8c070713          	addi	a4,a4,-1856 # 80008910 <timer_scratch>
    80000058:	9736                	add	a4,a4,a3
  scratch[3] = CLINT_MTIMECMP(id);
    8000005a:	ef1c                	sd	a5,24(a4)
  scratch[4] = interval;
    8000005c:	f310                	sd	a2,32(a4)
}

static inline void 
w_mscratch(uint64 x)
{
  asm volatile("csrw mscratch, %0" : : "r" (x));
    8000005e:	34071073          	csrw	mscratch,a4
  asm volatile("csrw mtvec, %0" : : "r" (x));
    80000062:	00006797          	auipc	a5,0x6
    80000066:	29e78793          	addi	a5,a5,670 # 80006300 <timervec>
    8000006a:	30579073          	csrw	mtvec,a5
  asm volatile("csrr %0, mstatus" : "=r" (x) );
    8000006e:	300027f3          	csrr	a5,mstatus

  // set the machine-mode trap handler.
  w_mtvec((uint64)timervec);

  // enable machine-mode interrupts.
  w_mstatus(r_mstatus() | MSTATUS_MIE);
    80000072:	0087e793          	ori	a5,a5,8
  asm volatile("csrw mstatus, %0" : : "r" (x));
    80000076:	30079073          	csrw	mstatus,a5
  asm volatile("csrr %0, mie" : "=r" (x) );
    8000007a:	304027f3          	csrr	a5,mie

  // enable machine-mode timer interrupts.
  w_mie(r_mie() | MIE_MTIE);
    8000007e:	0807e793          	ori	a5,a5,128
  asm volatile("csrw mie, %0" : : "r" (x));
    80000082:	30479073          	csrw	mie,a5
}
    80000086:	6422                	ld	s0,8(sp)
    80000088:	0141                	addi	sp,sp,16
    8000008a:	8082                	ret

000000008000008c <start>:
{
    8000008c:	1141                	addi	sp,sp,-16
    8000008e:	e406                	sd	ra,8(sp)
    80000090:	e022                	sd	s0,0(sp)
    80000092:	0800                	addi	s0,sp,16
  asm volatile("csrr %0, mstatus" : "=r" (x) );
    80000094:	300027f3          	csrr	a5,mstatus
  x &= ~MSTATUS_MPP_MASK;
    80000098:	7779                	lui	a4,0xffffe
    8000009a:	7ff70713          	addi	a4,a4,2047 # ffffffffffffe7ff <end+0xffffffff7ffdbc7f>
    8000009e:	8ff9                	and	a5,a5,a4
  x |= MSTATUS_MPP_S;
    800000a0:	6705                	lui	a4,0x1
    800000a2:	80070713          	addi	a4,a4,-2048 # 800 <_entry-0x7ffff800>
    800000a6:	8fd9                	or	a5,a5,a4
  asm volatile("csrw mstatus, %0" : : "r" (x));
    800000a8:	30079073          	csrw	mstatus,a5
  asm volatile("csrw mepc, %0" : : "r" (x));
    800000ac:	00001797          	auipc	a5,0x1
    800000b0:	dcc78793          	addi	a5,a5,-564 # 80000e78 <main>
    800000b4:	34179073          	csrw	mepc,a5
  asm volatile("csrw satp, %0" : : "r" (x));
    800000b8:	4781                	li	a5,0
    800000ba:	18079073          	csrw	satp,a5
  asm volatile("csrw medeleg, %0" : : "r" (x));
    800000be:	67c1                	lui	a5,0x10
    800000c0:	17fd                	addi	a5,a5,-1 # ffff <_entry-0x7fff0001>
    800000c2:	30279073          	csrw	medeleg,a5
  asm volatile("csrw mideleg, %0" : : "r" (x));
    800000c6:	30379073          	csrw	mideleg,a5
  asm volatile("csrr %0, sie" : "=r" (x) );
    800000ca:	104027f3          	csrr	a5,sie
  w_sie(r_sie() | SIE_SEIE | SIE_STIE | SIE_SSIE);
    800000ce:	2227e793          	ori	a5,a5,546
  asm volatile("csrw sie, %0" : : "r" (x));
    800000d2:	10479073          	csrw	sie,a5
  asm volatile("csrw pmpaddr0, %0" : : "r" (x));
    800000d6:	57fd                	li	a5,-1
    800000d8:	83a9                	srli	a5,a5,0xa
    800000da:	3b079073          	csrw	pmpaddr0,a5
  asm volatile("csrw pmpcfg0, %0" : : "r" (x));
    800000de:	47bd                	li	a5,15
    800000e0:	3a079073          	csrw	pmpcfg0,a5
  timerinit();
    800000e4:	00000097          	auipc	ra,0x0
    800000e8:	f38080e7          	jalr	-200(ra) # 8000001c <timerinit>
  asm volatile("csrr %0, mhartid" : "=r" (x) );
    800000ec:	f14027f3          	csrr	a5,mhartid
  w_tp(id);
    800000f0:	2781                	sext.w	a5,a5
}

static inline void 
w_tp(uint64 x)
{
  asm volatile("mv tp, %0" : : "r" (x));
    800000f2:	823e                	mv	tp,a5
  asm volatile("mret");
    800000f4:	30200073          	mret
}
    800000f8:	60a2                	ld	ra,8(sp)
    800000fa:	6402                	ld	s0,0(sp)
    800000fc:	0141                	addi	sp,sp,16
    800000fe:	8082                	ret

0000000080000100 <consolewrite>:
//
// user write()s to the console go here.
//
int
consolewrite(int user_src, uint64 src, int n)
{
    80000100:	715d                	addi	sp,sp,-80
    80000102:	e486                	sd	ra,72(sp)
    80000104:	e0a2                	sd	s0,64(sp)
    80000106:	fc26                	sd	s1,56(sp)
    80000108:	f84a                	sd	s2,48(sp)
    8000010a:	f44e                	sd	s3,40(sp)
    8000010c:	f052                	sd	s4,32(sp)
    8000010e:	ec56                	sd	s5,24(sp)
    80000110:	0880                	addi	s0,sp,80
  int i;

  for(i = 0; i < n; i++){
    80000112:	04c05763          	blez	a2,80000160 <consolewrite+0x60>
    80000116:	8a2a                	mv	s4,a0
    80000118:	84ae                	mv	s1,a1
    8000011a:	89b2                	mv	s3,a2
    8000011c:	4901                	li	s2,0
    char c;
    if(either_copyin(&c, user_src, src+i, 1) == -1)
    8000011e:	5afd                	li	s5,-1
    80000120:	4685                	li	a3,1
    80000122:	8626                	mv	a2,s1
    80000124:	85d2                	mv	a1,s4
    80000126:	fbf40513          	addi	a0,s0,-65
    8000012a:	00002097          	auipc	ra,0x2
    8000012e:	478080e7          	jalr	1144(ra) # 800025a2 <either_copyin>
    80000132:	01550d63          	beq	a0,s5,8000014c <consolewrite+0x4c>
      break;
    uartputc(c);
    80000136:	fbf44503          	lbu	a0,-65(s0)
    8000013a:	00000097          	auipc	ra,0x0
    8000013e:	784080e7          	jalr	1924(ra) # 800008be <uartputc>
  for(i = 0; i < n; i++){
    80000142:	2905                	addiw	s2,s2,1
    80000144:	0485                	addi	s1,s1,1
    80000146:	fd299de3          	bne	s3,s2,80000120 <consolewrite+0x20>
    8000014a:	894e                	mv	s2,s3
  }

  return i;
}
    8000014c:	854a                	mv	a0,s2
    8000014e:	60a6                	ld	ra,72(sp)
    80000150:	6406                	ld	s0,64(sp)
    80000152:	74e2                	ld	s1,56(sp)
    80000154:	7942                	ld	s2,48(sp)
    80000156:	79a2                	ld	s3,40(sp)
    80000158:	7a02                	ld	s4,32(sp)
    8000015a:	6ae2                	ld	s5,24(sp)
    8000015c:	6161                	addi	sp,sp,80
    8000015e:	8082                	ret
  for(i = 0; i < n; i++){
    80000160:	4901                	li	s2,0
    80000162:	b7ed                	j	8000014c <consolewrite+0x4c>

0000000080000164 <consoleread>:
// user_dist indicates whether dst is a user
// or kernel address.
//
int
consoleread(int user_dst, uint64 dst, int n)
{
    80000164:	7159                	addi	sp,sp,-112
    80000166:	f486                	sd	ra,104(sp)
    80000168:	f0a2                	sd	s0,96(sp)
    8000016a:	eca6                	sd	s1,88(sp)
    8000016c:	e8ca                	sd	s2,80(sp)
    8000016e:	e4ce                	sd	s3,72(sp)
    80000170:	e0d2                	sd	s4,64(sp)
    80000172:	fc56                	sd	s5,56(sp)
    80000174:	f85a                	sd	s6,48(sp)
    80000176:	f45e                	sd	s7,40(sp)
    80000178:	f062                	sd	s8,32(sp)
    8000017a:	ec66                	sd	s9,24(sp)
    8000017c:	e86a                	sd	s10,16(sp)
    8000017e:	1880                	addi	s0,sp,112
    80000180:	8aaa                	mv	s5,a0
    80000182:	8a2e                	mv	s4,a1
    80000184:	89b2                	mv	s3,a2
  uint target;
  int c;
  char cbuf;

  target = n;
    80000186:	00060b1b          	sext.w	s6,a2
  acquire(&cons.lock);
    8000018a:	00011517          	auipc	a0,0x11
    8000018e:	8c650513          	addi	a0,a0,-1850 # 80010a50 <cons>
    80000192:	00001097          	auipc	ra,0x1
    80000196:	a44080e7          	jalr	-1468(ra) # 80000bd6 <acquire>
  while(n > 0){
    // wait until interrupt handler has put some
    // input into cons.buffer.
    while(cons.r == cons.w){
    8000019a:	00011497          	auipc	s1,0x11
    8000019e:	8b648493          	addi	s1,s1,-1866 # 80010a50 <cons>
      if(killed(myproc())){
        release(&cons.lock);
        return -1;
      }
      sleep(&cons.r, &cons.lock);
    800001a2:	00011917          	auipc	s2,0x11
    800001a6:	94690913          	addi	s2,s2,-1722 # 80010ae8 <cons+0x98>
    }

    c = cons.buf[cons.r++ % INPUT_BUF_SIZE];

    if(c == C('D')){  // end-of-file
    800001aa:	4b91                	li	s7,4
      break;
    }

    // copy the input byte to the user-space buffer.
    cbuf = c;
    if(either_copyout(user_dst, dst, &cbuf, 1) == -1)
    800001ac:	5c7d                	li	s8,-1
      break;

    dst++;
    --n;

    if(c == '\n'){
    800001ae:	4ca9                	li	s9,10
  while(n > 0){
    800001b0:	07305b63          	blez	s3,80000226 <consoleread+0xc2>
    while(cons.r == cons.w){
    800001b4:	0984a783          	lw	a5,152(s1)
    800001b8:	09c4a703          	lw	a4,156(s1)
    800001bc:	02f71763          	bne	a4,a5,800001ea <consoleread+0x86>
      if(killed(myproc())){
    800001c0:	00001097          	auipc	ra,0x1
    800001c4:	7ec080e7          	jalr	2028(ra) # 800019ac <myproc>
    800001c8:	00002097          	auipc	ra,0x2
    800001cc:	224080e7          	jalr	548(ra) # 800023ec <killed>
    800001d0:	e535                	bnez	a0,8000023c <consoleread+0xd8>
      sleep(&cons.r, &cons.lock);
    800001d2:	85a6                	mv	a1,s1
    800001d4:	854a                	mv	a0,s2
    800001d6:	00002097          	auipc	ra,0x2
    800001da:	f42080e7          	jalr	-190(ra) # 80002118 <sleep>
    while(cons.r == cons.w){
    800001de:	0984a783          	lw	a5,152(s1)
    800001e2:	09c4a703          	lw	a4,156(s1)
    800001e6:	fcf70de3          	beq	a4,a5,800001c0 <consoleread+0x5c>
    c = cons.buf[cons.r++ % INPUT_BUF_SIZE];
    800001ea:	0017871b          	addiw	a4,a5,1
    800001ee:	08e4ac23          	sw	a4,152(s1)
    800001f2:	07f7f713          	andi	a4,a5,127
    800001f6:	9726                	add	a4,a4,s1
    800001f8:	01874703          	lbu	a4,24(a4)
    800001fc:	00070d1b          	sext.w	s10,a4
    if(c == C('D')){  // end-of-file
    80000200:	077d0563          	beq	s10,s7,8000026a <consoleread+0x106>
    cbuf = c;
    80000204:	f8e40fa3          	sb	a4,-97(s0)
    if(either_copyout(user_dst, dst, &cbuf, 1) == -1)
    80000208:	4685                	li	a3,1
    8000020a:	f9f40613          	addi	a2,s0,-97
    8000020e:	85d2                	mv	a1,s4
    80000210:	8556                	mv	a0,s5
    80000212:	00002097          	auipc	ra,0x2
    80000216:	33a080e7          	jalr	826(ra) # 8000254c <either_copyout>
    8000021a:	01850663          	beq	a0,s8,80000226 <consoleread+0xc2>
    dst++;
    8000021e:	0a05                	addi	s4,s4,1
    --n;
    80000220:	39fd                	addiw	s3,s3,-1
    if(c == '\n'){
    80000222:	f99d17e3          	bne	s10,s9,800001b0 <consoleread+0x4c>
      // a whole line has arrived, return to
      // the user-level read().
      break;
    }
  }
  release(&cons.lock);
    80000226:	00011517          	auipc	a0,0x11
    8000022a:	82a50513          	addi	a0,a0,-2006 # 80010a50 <cons>
    8000022e:	00001097          	auipc	ra,0x1
    80000232:	a5c080e7          	jalr	-1444(ra) # 80000c8a <release>

  return target - n;
    80000236:	413b053b          	subw	a0,s6,s3
    8000023a:	a811                	j	8000024e <consoleread+0xea>
        release(&cons.lock);
    8000023c:	00011517          	auipc	a0,0x11
    80000240:	81450513          	addi	a0,a0,-2028 # 80010a50 <cons>
    80000244:	00001097          	auipc	ra,0x1
    80000248:	a46080e7          	jalr	-1466(ra) # 80000c8a <release>
        return -1;
    8000024c:	557d                	li	a0,-1
}
    8000024e:	70a6                	ld	ra,104(sp)
    80000250:	7406                	ld	s0,96(sp)
    80000252:	64e6                	ld	s1,88(sp)
    80000254:	6946                	ld	s2,80(sp)
    80000256:	69a6                	ld	s3,72(sp)
    80000258:	6a06                	ld	s4,64(sp)
    8000025a:	7ae2                	ld	s5,56(sp)
    8000025c:	7b42                	ld	s6,48(sp)
    8000025e:	7ba2                	ld	s7,40(sp)
    80000260:	7c02                	ld	s8,32(sp)
    80000262:	6ce2                	ld	s9,24(sp)
    80000264:	6d42                	ld	s10,16(sp)
    80000266:	6165                	addi	sp,sp,112
    80000268:	8082                	ret
      if(n < target){
    8000026a:	0009871b          	sext.w	a4,s3
    8000026e:	fb677ce3          	bgeu	a4,s6,80000226 <consoleread+0xc2>
        cons.r--;
    80000272:	00011717          	auipc	a4,0x11
    80000276:	86f72b23          	sw	a5,-1930(a4) # 80010ae8 <cons+0x98>
    8000027a:	b775                	j	80000226 <consoleread+0xc2>

000000008000027c <consputc>:
{
    8000027c:	1141                	addi	sp,sp,-16
    8000027e:	e406                	sd	ra,8(sp)
    80000280:	e022                	sd	s0,0(sp)
    80000282:	0800                	addi	s0,sp,16
  if(c == BACKSPACE){
    80000284:	10000793          	li	a5,256
    80000288:	00f50a63          	beq	a0,a5,8000029c <consputc+0x20>
    uartputc_sync(c);
    8000028c:	00000097          	auipc	ra,0x0
    80000290:	560080e7          	jalr	1376(ra) # 800007ec <uartputc_sync>
}
    80000294:	60a2                	ld	ra,8(sp)
    80000296:	6402                	ld	s0,0(sp)
    80000298:	0141                	addi	sp,sp,16
    8000029a:	8082                	ret
    uartputc_sync('\b'); uartputc_sync(' '); uartputc_sync('\b');
    8000029c:	4521                	li	a0,8
    8000029e:	00000097          	auipc	ra,0x0
    800002a2:	54e080e7          	jalr	1358(ra) # 800007ec <uartputc_sync>
    800002a6:	02000513          	li	a0,32
    800002aa:	00000097          	auipc	ra,0x0
    800002ae:	542080e7          	jalr	1346(ra) # 800007ec <uartputc_sync>
    800002b2:	4521                	li	a0,8
    800002b4:	00000097          	auipc	ra,0x0
    800002b8:	538080e7          	jalr	1336(ra) # 800007ec <uartputc_sync>
    800002bc:	bfe1                	j	80000294 <consputc+0x18>

00000000800002be <consoleintr>:
// do erase/kill processing, append to cons.buf,
// wake up consoleread() if a whole line has arrived.
//
void
consoleintr(int c)
{
    800002be:	1101                	addi	sp,sp,-32
    800002c0:	ec06                	sd	ra,24(sp)
    800002c2:	e822                	sd	s0,16(sp)
    800002c4:	e426                	sd	s1,8(sp)
    800002c6:	e04a                	sd	s2,0(sp)
    800002c8:	1000                	addi	s0,sp,32
    800002ca:	84aa                	mv	s1,a0
  acquire(&cons.lock);
    800002cc:	00010517          	auipc	a0,0x10
    800002d0:	78450513          	addi	a0,a0,1924 # 80010a50 <cons>
    800002d4:	00001097          	auipc	ra,0x1
    800002d8:	902080e7          	jalr	-1790(ra) # 80000bd6 <acquire>

  switch(c){
    800002dc:	47d5                	li	a5,21
    800002de:	0af48663          	beq	s1,a5,8000038a <consoleintr+0xcc>
    800002e2:	0297ca63          	blt	a5,s1,80000316 <consoleintr+0x58>
    800002e6:	47a1                	li	a5,8
    800002e8:	0ef48763          	beq	s1,a5,800003d6 <consoleintr+0x118>
    800002ec:	47c1                	li	a5,16
    800002ee:	10f49a63          	bne	s1,a5,80000402 <consoleintr+0x144>
  case C('P'):  // Print process list.
    procdump();
    800002f2:	00002097          	auipc	ra,0x2
    800002f6:	306080e7          	jalr	774(ra) # 800025f8 <procdump>
      }
    }
    break;
  }
  
  release(&cons.lock);
    800002fa:	00010517          	auipc	a0,0x10
    800002fe:	75650513          	addi	a0,a0,1878 # 80010a50 <cons>
    80000302:	00001097          	auipc	ra,0x1
    80000306:	988080e7          	jalr	-1656(ra) # 80000c8a <release>
}
    8000030a:	60e2                	ld	ra,24(sp)
    8000030c:	6442                	ld	s0,16(sp)
    8000030e:	64a2                	ld	s1,8(sp)
    80000310:	6902                	ld	s2,0(sp)
    80000312:	6105                	addi	sp,sp,32
    80000314:	8082                	ret
  switch(c){
    80000316:	07f00793          	li	a5,127
    8000031a:	0af48e63          	beq	s1,a5,800003d6 <consoleintr+0x118>
    if(c != 0 && cons.e-cons.r < INPUT_BUF_SIZE){
    8000031e:	00010717          	auipc	a4,0x10
    80000322:	73270713          	addi	a4,a4,1842 # 80010a50 <cons>
    80000326:	0a072783          	lw	a5,160(a4)
    8000032a:	09872703          	lw	a4,152(a4)
    8000032e:	9f99                	subw	a5,a5,a4
    80000330:	07f00713          	li	a4,127
    80000334:	fcf763e3          	bltu	a4,a5,800002fa <consoleintr+0x3c>
      c = (c == '\r') ? '\n' : c;
    80000338:	47b5                	li	a5,13
    8000033a:	0cf48763          	beq	s1,a5,80000408 <consoleintr+0x14a>
      consputc(c);
    8000033e:	8526                	mv	a0,s1
    80000340:	00000097          	auipc	ra,0x0
    80000344:	f3c080e7          	jalr	-196(ra) # 8000027c <consputc>
      cons.buf[cons.e++ % INPUT_BUF_SIZE] = c;
    80000348:	00010797          	auipc	a5,0x10
    8000034c:	70878793          	addi	a5,a5,1800 # 80010a50 <cons>
    80000350:	0a07a683          	lw	a3,160(a5)
    80000354:	0016871b          	addiw	a4,a3,1
    80000358:	0007061b          	sext.w	a2,a4
    8000035c:	0ae7a023          	sw	a4,160(a5)
    80000360:	07f6f693          	andi	a3,a3,127
    80000364:	97b6                	add	a5,a5,a3
    80000366:	00978c23          	sb	s1,24(a5)
      if(c == '\n' || c == C('D') || cons.e-cons.r == INPUT_BUF_SIZE){
    8000036a:	47a9                	li	a5,10
    8000036c:	0cf48563          	beq	s1,a5,80000436 <consoleintr+0x178>
    80000370:	4791                	li	a5,4
    80000372:	0cf48263          	beq	s1,a5,80000436 <consoleintr+0x178>
    80000376:	00010797          	auipc	a5,0x10
    8000037a:	7727a783          	lw	a5,1906(a5) # 80010ae8 <cons+0x98>
    8000037e:	9f1d                	subw	a4,a4,a5
    80000380:	08000793          	li	a5,128
    80000384:	f6f71be3          	bne	a4,a5,800002fa <consoleintr+0x3c>
    80000388:	a07d                	j	80000436 <consoleintr+0x178>
    while(cons.e != cons.w &&
    8000038a:	00010717          	auipc	a4,0x10
    8000038e:	6c670713          	addi	a4,a4,1734 # 80010a50 <cons>
    80000392:	0a072783          	lw	a5,160(a4)
    80000396:	09c72703          	lw	a4,156(a4)
          cons.buf[(cons.e-1) % INPUT_BUF_SIZE] != '\n'){
    8000039a:	00010497          	auipc	s1,0x10
    8000039e:	6b648493          	addi	s1,s1,1718 # 80010a50 <cons>
    while(cons.e != cons.w &&
    800003a2:	4929                	li	s2,10
    800003a4:	f4f70be3          	beq	a4,a5,800002fa <consoleintr+0x3c>
          cons.buf[(cons.e-1) % INPUT_BUF_SIZE] != '\n'){
    800003a8:	37fd                	addiw	a5,a5,-1
    800003aa:	07f7f713          	andi	a4,a5,127
    800003ae:	9726                	add	a4,a4,s1
    while(cons.e != cons.w &&
    800003b0:	01874703          	lbu	a4,24(a4)
    800003b4:	f52703e3          	beq	a4,s2,800002fa <consoleintr+0x3c>
      cons.e--;
    800003b8:	0af4a023          	sw	a5,160(s1)
      consputc(BACKSPACE);
    800003bc:	10000513          	li	a0,256
    800003c0:	00000097          	auipc	ra,0x0
    800003c4:	ebc080e7          	jalr	-324(ra) # 8000027c <consputc>
    while(cons.e != cons.w &&
    800003c8:	0a04a783          	lw	a5,160(s1)
    800003cc:	09c4a703          	lw	a4,156(s1)
    800003d0:	fcf71ce3          	bne	a4,a5,800003a8 <consoleintr+0xea>
    800003d4:	b71d                	j	800002fa <consoleintr+0x3c>
    if(cons.e != cons.w){
    800003d6:	00010717          	auipc	a4,0x10
    800003da:	67a70713          	addi	a4,a4,1658 # 80010a50 <cons>
    800003de:	0a072783          	lw	a5,160(a4)
    800003e2:	09c72703          	lw	a4,156(a4)
    800003e6:	f0f70ae3          	beq	a4,a5,800002fa <consoleintr+0x3c>
      cons.e--;
    800003ea:	37fd                	addiw	a5,a5,-1
    800003ec:	00010717          	auipc	a4,0x10
    800003f0:	70f72223          	sw	a5,1796(a4) # 80010af0 <cons+0xa0>
      consputc(BACKSPACE);
    800003f4:	10000513          	li	a0,256
    800003f8:	00000097          	auipc	ra,0x0
    800003fc:	e84080e7          	jalr	-380(ra) # 8000027c <consputc>
    80000400:	bded                	j	800002fa <consoleintr+0x3c>
    if(c != 0 && cons.e-cons.r < INPUT_BUF_SIZE){
    80000402:	ee048ce3          	beqz	s1,800002fa <consoleintr+0x3c>
    80000406:	bf21                	j	8000031e <consoleintr+0x60>
      consputc(c);
    80000408:	4529                	li	a0,10
    8000040a:	00000097          	auipc	ra,0x0
    8000040e:	e72080e7          	jalr	-398(ra) # 8000027c <consputc>
      cons.buf[cons.e++ % INPUT_BUF_SIZE] = c;
    80000412:	00010797          	auipc	a5,0x10
    80000416:	63e78793          	addi	a5,a5,1598 # 80010a50 <cons>
    8000041a:	0a07a703          	lw	a4,160(a5)
    8000041e:	0017069b          	addiw	a3,a4,1
    80000422:	0006861b          	sext.w	a2,a3
    80000426:	0ad7a023          	sw	a3,160(a5)
    8000042a:	07f77713          	andi	a4,a4,127
    8000042e:	97ba                	add	a5,a5,a4
    80000430:	4729                	li	a4,10
    80000432:	00e78c23          	sb	a4,24(a5)
        cons.w = cons.e;
    80000436:	00010797          	auipc	a5,0x10
    8000043a:	6ac7ab23          	sw	a2,1718(a5) # 80010aec <cons+0x9c>
        wakeup(&cons.r);
    8000043e:	00010517          	auipc	a0,0x10
    80000442:	6aa50513          	addi	a0,a0,1706 # 80010ae8 <cons+0x98>
    80000446:	00002097          	auipc	ra,0x2
    8000044a:	d36080e7          	jalr	-714(ra) # 8000217c <wakeup>
    8000044e:	b575                	j	800002fa <consoleintr+0x3c>

0000000080000450 <consoleinit>:

void
consoleinit(void)
{
    80000450:	1141                	addi	sp,sp,-16
    80000452:	e406                	sd	ra,8(sp)
    80000454:	e022                	sd	s0,0(sp)
    80000456:	0800                	addi	s0,sp,16
  initlock(&cons.lock, "cons");
    80000458:	00008597          	auipc	a1,0x8
    8000045c:	bb858593          	addi	a1,a1,-1096 # 80008010 <etext+0x10>
    80000460:	00010517          	auipc	a0,0x10
    80000464:	5f050513          	addi	a0,a0,1520 # 80010a50 <cons>
    80000468:	00000097          	auipc	ra,0x0
    8000046c:	6de080e7          	jalr	1758(ra) # 80000b46 <initlock>

  uartinit();
    80000470:	00000097          	auipc	ra,0x0
    80000474:	32c080e7          	jalr	812(ra) # 8000079c <uartinit>

  // connect read and write system calls
  // to consoleread and consolewrite.
  devsw[CONSOLE].read = consoleread;
    80000478:	00021797          	auipc	a5,0x21
    8000047c:	57078793          	addi	a5,a5,1392 # 800219e8 <devsw>
    80000480:	00000717          	auipc	a4,0x0
    80000484:	ce470713          	addi	a4,a4,-796 # 80000164 <consoleread>
    80000488:	eb98                	sd	a4,16(a5)
  devsw[CONSOLE].write = consolewrite;
    8000048a:	00000717          	auipc	a4,0x0
    8000048e:	c7670713          	addi	a4,a4,-906 # 80000100 <consolewrite>
    80000492:	ef98                	sd	a4,24(a5)
}
    80000494:	60a2                	ld	ra,8(sp)
    80000496:	6402                	ld	s0,0(sp)
    80000498:	0141                	addi	sp,sp,16
    8000049a:	8082                	ret

000000008000049c <printint>:

static char digits[] = "0123456789abcdef";

static void
printint(int xx, int base, int sign)
{
    8000049c:	7179                	addi	sp,sp,-48
    8000049e:	f406                	sd	ra,40(sp)
    800004a0:	f022                	sd	s0,32(sp)
    800004a2:	ec26                	sd	s1,24(sp)
    800004a4:	e84a                	sd	s2,16(sp)
    800004a6:	1800                	addi	s0,sp,48
  char buf[16];
  int i;
  uint x;

  if(sign && (sign = xx < 0))
    800004a8:	c219                	beqz	a2,800004ae <printint+0x12>
    800004aa:	08054763          	bltz	a0,80000538 <printint+0x9c>
    x = -xx;
  else
    x = xx;
    800004ae:	2501                	sext.w	a0,a0
    800004b0:	4881                	li	a7,0
    800004b2:	fd040693          	addi	a3,s0,-48

  i = 0;
    800004b6:	4701                	li	a4,0
  do {
    buf[i++] = digits[x % base];
    800004b8:	2581                	sext.w	a1,a1
    800004ba:	00008617          	auipc	a2,0x8
    800004be:	b8660613          	addi	a2,a2,-1146 # 80008040 <digits>
    800004c2:	883a                	mv	a6,a4
    800004c4:	2705                	addiw	a4,a4,1
    800004c6:	02b577bb          	remuw	a5,a0,a1
    800004ca:	1782                	slli	a5,a5,0x20
    800004cc:	9381                	srli	a5,a5,0x20
    800004ce:	97b2                	add	a5,a5,a2
    800004d0:	0007c783          	lbu	a5,0(a5)
    800004d4:	00f68023          	sb	a5,0(a3)
  } while((x /= base) != 0);
    800004d8:	0005079b          	sext.w	a5,a0
    800004dc:	02b5553b          	divuw	a0,a0,a1
    800004e0:	0685                	addi	a3,a3,1
    800004e2:	feb7f0e3          	bgeu	a5,a1,800004c2 <printint+0x26>

  if(sign)
    800004e6:	00088c63          	beqz	a7,800004fe <printint+0x62>
    buf[i++] = '-';
    800004ea:	fe070793          	addi	a5,a4,-32
    800004ee:	00878733          	add	a4,a5,s0
    800004f2:	02d00793          	li	a5,45
    800004f6:	fef70823          	sb	a5,-16(a4)
    800004fa:	0028071b          	addiw	a4,a6,2

  while(--i >= 0)
    800004fe:	02e05763          	blez	a4,8000052c <printint+0x90>
    80000502:	fd040793          	addi	a5,s0,-48
    80000506:	00e784b3          	add	s1,a5,a4
    8000050a:	fff78913          	addi	s2,a5,-1
    8000050e:	993a                	add	s2,s2,a4
    80000510:	377d                	addiw	a4,a4,-1
    80000512:	1702                	slli	a4,a4,0x20
    80000514:	9301                	srli	a4,a4,0x20
    80000516:	40e90933          	sub	s2,s2,a4
    consputc(buf[i]);
    8000051a:	fff4c503          	lbu	a0,-1(s1)
    8000051e:	00000097          	auipc	ra,0x0
    80000522:	d5e080e7          	jalr	-674(ra) # 8000027c <consputc>
  while(--i >= 0)
    80000526:	14fd                	addi	s1,s1,-1
    80000528:	ff2499e3          	bne	s1,s2,8000051a <printint+0x7e>
}
    8000052c:	70a2                	ld	ra,40(sp)
    8000052e:	7402                	ld	s0,32(sp)
    80000530:	64e2                	ld	s1,24(sp)
    80000532:	6942                	ld	s2,16(sp)
    80000534:	6145                	addi	sp,sp,48
    80000536:	8082                	ret
    x = -xx;
    80000538:	40a0053b          	negw	a0,a0
  if(sign && (sign = xx < 0))
    8000053c:	4885                	li	a7,1
    x = -xx;
    8000053e:	bf95                	j	800004b2 <printint+0x16>

0000000080000540 <panic>:
    release(&pr.lock);
}

void
panic(char *s)
{
    80000540:	1101                	addi	sp,sp,-32
    80000542:	ec06                	sd	ra,24(sp)
    80000544:	e822                	sd	s0,16(sp)
    80000546:	e426                	sd	s1,8(sp)
    80000548:	1000                	addi	s0,sp,32
    8000054a:	84aa                	mv	s1,a0
  pr.locking = 0;
    8000054c:	00010797          	auipc	a5,0x10
    80000550:	5c07a223          	sw	zero,1476(a5) # 80010b10 <pr+0x18>
  printf("panic: ");
    80000554:	00008517          	auipc	a0,0x8
    80000558:	ac450513          	addi	a0,a0,-1340 # 80008018 <etext+0x18>
    8000055c:	00000097          	auipc	ra,0x0
    80000560:	02e080e7          	jalr	46(ra) # 8000058a <printf>
  printf(s);
    80000564:	8526                	mv	a0,s1
    80000566:	00000097          	auipc	ra,0x0
    8000056a:	024080e7          	jalr	36(ra) # 8000058a <printf>
  printf("\n");
    8000056e:	00008517          	auipc	a0,0x8
    80000572:	b5a50513          	addi	a0,a0,-1190 # 800080c8 <digits+0x88>
    80000576:	00000097          	auipc	ra,0x0
    8000057a:	014080e7          	jalr	20(ra) # 8000058a <printf>
  panicked = 1; // freeze uart output from other CPUs
    8000057e:	4785                	li	a5,1
    80000580:	00008717          	auipc	a4,0x8
    80000584:	34f72823          	sw	a5,848(a4) # 800088d0 <panicked>
  for(;;)
    80000588:	a001                	j	80000588 <panic+0x48>

000000008000058a <printf>:
{
    8000058a:	7131                	addi	sp,sp,-192
    8000058c:	fc86                	sd	ra,120(sp)
    8000058e:	f8a2                	sd	s0,112(sp)
    80000590:	f4a6                	sd	s1,104(sp)
    80000592:	f0ca                	sd	s2,96(sp)
    80000594:	ecce                	sd	s3,88(sp)
    80000596:	e8d2                	sd	s4,80(sp)
    80000598:	e4d6                	sd	s5,72(sp)
    8000059a:	e0da                	sd	s6,64(sp)
    8000059c:	fc5e                	sd	s7,56(sp)
    8000059e:	f862                	sd	s8,48(sp)
    800005a0:	f466                	sd	s9,40(sp)
    800005a2:	f06a                	sd	s10,32(sp)
    800005a4:	ec6e                	sd	s11,24(sp)
    800005a6:	0100                	addi	s0,sp,128
    800005a8:	8a2a                	mv	s4,a0
    800005aa:	e40c                	sd	a1,8(s0)
    800005ac:	e810                	sd	a2,16(s0)
    800005ae:	ec14                	sd	a3,24(s0)
    800005b0:	f018                	sd	a4,32(s0)
    800005b2:	f41c                	sd	a5,40(s0)
    800005b4:	03043823          	sd	a6,48(s0)
    800005b8:	03143c23          	sd	a7,56(s0)
  locking = pr.locking;
    800005bc:	00010d97          	auipc	s11,0x10
    800005c0:	554dad83          	lw	s11,1364(s11) # 80010b10 <pr+0x18>
  if(locking)
    800005c4:	020d9b63          	bnez	s11,800005fa <printf+0x70>
  if (fmt == 0)
    800005c8:	040a0263          	beqz	s4,8000060c <printf+0x82>
  va_start(ap, fmt);
    800005cc:	00840793          	addi	a5,s0,8
    800005d0:	f8f43423          	sd	a5,-120(s0)
  for(i = 0; (c = fmt[i] & 0xff) != 0; i++){
    800005d4:	000a4503          	lbu	a0,0(s4)
    800005d8:	14050f63          	beqz	a0,80000736 <printf+0x1ac>
    800005dc:	4981                	li	s3,0
    if(c != '%'){
    800005de:	02500a93          	li	s5,37
    switch(c){
    800005e2:	07000b93          	li	s7,112
  consputc('x');
    800005e6:	4d41                	li	s10,16
    consputc(digits[x >> (sizeof(uint64) * 8 - 4)]);
    800005e8:	00008b17          	auipc	s6,0x8
    800005ec:	a58b0b13          	addi	s6,s6,-1448 # 80008040 <digits>
    switch(c){
    800005f0:	07300c93          	li	s9,115
    800005f4:	06400c13          	li	s8,100
    800005f8:	a82d                	j	80000632 <printf+0xa8>
    acquire(&pr.lock);
    800005fa:	00010517          	auipc	a0,0x10
    800005fe:	4fe50513          	addi	a0,a0,1278 # 80010af8 <pr>
    80000602:	00000097          	auipc	ra,0x0
    80000606:	5d4080e7          	jalr	1492(ra) # 80000bd6 <acquire>
    8000060a:	bf7d                	j	800005c8 <printf+0x3e>
    panic("null fmt");
    8000060c:	00008517          	auipc	a0,0x8
    80000610:	a1c50513          	addi	a0,a0,-1508 # 80008028 <etext+0x28>
    80000614:	00000097          	auipc	ra,0x0
    80000618:	f2c080e7          	jalr	-212(ra) # 80000540 <panic>
      consputc(c);
    8000061c:	00000097          	auipc	ra,0x0
    80000620:	c60080e7          	jalr	-928(ra) # 8000027c <consputc>
  for(i = 0; (c = fmt[i] & 0xff) != 0; i++){
    80000624:	2985                	addiw	s3,s3,1
    80000626:	013a07b3          	add	a5,s4,s3
    8000062a:	0007c503          	lbu	a0,0(a5)
    8000062e:	10050463          	beqz	a0,80000736 <printf+0x1ac>
    if(c != '%'){
    80000632:	ff5515e3          	bne	a0,s5,8000061c <printf+0x92>
    c = fmt[++i] & 0xff;
    80000636:	2985                	addiw	s3,s3,1
    80000638:	013a07b3          	add	a5,s4,s3
    8000063c:	0007c783          	lbu	a5,0(a5)
    80000640:	0007849b          	sext.w	s1,a5
    if(c == 0)
    80000644:	cbed                	beqz	a5,80000736 <printf+0x1ac>
    switch(c){
    80000646:	05778a63          	beq	a5,s7,8000069a <printf+0x110>
    8000064a:	02fbf663          	bgeu	s7,a5,80000676 <printf+0xec>
    8000064e:	09978863          	beq	a5,s9,800006de <printf+0x154>
    80000652:	07800713          	li	a4,120
    80000656:	0ce79563          	bne	a5,a4,80000720 <printf+0x196>
      printint(va_arg(ap, int), 16, 1);
    8000065a:	f8843783          	ld	a5,-120(s0)
    8000065e:	00878713          	addi	a4,a5,8
    80000662:	f8e43423          	sd	a4,-120(s0)
    80000666:	4605                	li	a2,1
    80000668:	85ea                	mv	a1,s10
    8000066a:	4388                	lw	a0,0(a5)
    8000066c:	00000097          	auipc	ra,0x0
    80000670:	e30080e7          	jalr	-464(ra) # 8000049c <printint>
      break;
    80000674:	bf45                	j	80000624 <printf+0x9a>
    switch(c){
    80000676:	09578f63          	beq	a5,s5,80000714 <printf+0x18a>
    8000067a:	0b879363          	bne	a5,s8,80000720 <printf+0x196>
      printint(va_arg(ap, int), 10, 1);
    8000067e:	f8843783          	ld	a5,-120(s0)
    80000682:	00878713          	addi	a4,a5,8
    80000686:	f8e43423          	sd	a4,-120(s0)
    8000068a:	4605                	li	a2,1
    8000068c:	45a9                	li	a1,10
    8000068e:	4388                	lw	a0,0(a5)
    80000690:	00000097          	auipc	ra,0x0
    80000694:	e0c080e7          	jalr	-500(ra) # 8000049c <printint>
      break;
    80000698:	b771                	j	80000624 <printf+0x9a>
      printptr(va_arg(ap, uint64));
    8000069a:	f8843783          	ld	a5,-120(s0)
    8000069e:	00878713          	addi	a4,a5,8
    800006a2:	f8e43423          	sd	a4,-120(s0)
    800006a6:	0007b903          	ld	s2,0(a5)
  consputc('0');
    800006aa:	03000513          	li	a0,48
    800006ae:	00000097          	auipc	ra,0x0
    800006b2:	bce080e7          	jalr	-1074(ra) # 8000027c <consputc>
  consputc('x');
    800006b6:	07800513          	li	a0,120
    800006ba:	00000097          	auipc	ra,0x0
    800006be:	bc2080e7          	jalr	-1086(ra) # 8000027c <consputc>
    800006c2:	84ea                	mv	s1,s10
    consputc(digits[x >> (sizeof(uint64) * 8 - 4)]);
    800006c4:	03c95793          	srli	a5,s2,0x3c
    800006c8:	97da                	add	a5,a5,s6
    800006ca:	0007c503          	lbu	a0,0(a5)
    800006ce:	00000097          	auipc	ra,0x0
    800006d2:	bae080e7          	jalr	-1106(ra) # 8000027c <consputc>
  for (i = 0; i < (sizeof(uint64) * 2); i++, x <<= 4)
    800006d6:	0912                	slli	s2,s2,0x4
    800006d8:	34fd                	addiw	s1,s1,-1
    800006da:	f4ed                	bnez	s1,800006c4 <printf+0x13a>
    800006dc:	b7a1                	j	80000624 <printf+0x9a>
      if((s = va_arg(ap, char*)) == 0)
    800006de:	f8843783          	ld	a5,-120(s0)
    800006e2:	00878713          	addi	a4,a5,8
    800006e6:	f8e43423          	sd	a4,-120(s0)
    800006ea:	6384                	ld	s1,0(a5)
    800006ec:	cc89                	beqz	s1,80000706 <printf+0x17c>
      for(; *s; s++)
    800006ee:	0004c503          	lbu	a0,0(s1)
    800006f2:	d90d                	beqz	a0,80000624 <printf+0x9a>
        consputc(*s);
    800006f4:	00000097          	auipc	ra,0x0
    800006f8:	b88080e7          	jalr	-1144(ra) # 8000027c <consputc>
      for(; *s; s++)
    800006fc:	0485                	addi	s1,s1,1
    800006fe:	0004c503          	lbu	a0,0(s1)
    80000702:	f96d                	bnez	a0,800006f4 <printf+0x16a>
    80000704:	b705                	j	80000624 <printf+0x9a>
        s = "(null)";
    80000706:	00008497          	auipc	s1,0x8
    8000070a:	91a48493          	addi	s1,s1,-1766 # 80008020 <etext+0x20>
      for(; *s; s++)
    8000070e:	02800513          	li	a0,40
    80000712:	b7cd                	j	800006f4 <printf+0x16a>
      consputc('%');
    80000714:	8556                	mv	a0,s5
    80000716:	00000097          	auipc	ra,0x0
    8000071a:	b66080e7          	jalr	-1178(ra) # 8000027c <consputc>
      break;
    8000071e:	b719                	j	80000624 <printf+0x9a>
      consputc('%');
    80000720:	8556                	mv	a0,s5
    80000722:	00000097          	auipc	ra,0x0
    80000726:	b5a080e7          	jalr	-1190(ra) # 8000027c <consputc>
      consputc(c);
    8000072a:	8526                	mv	a0,s1
    8000072c:	00000097          	auipc	ra,0x0
    80000730:	b50080e7          	jalr	-1200(ra) # 8000027c <consputc>
      break;
    80000734:	bdc5                	j	80000624 <printf+0x9a>
  if(locking)
    80000736:	020d9163          	bnez	s11,80000758 <printf+0x1ce>
}
    8000073a:	70e6                	ld	ra,120(sp)
    8000073c:	7446                	ld	s0,112(sp)
    8000073e:	74a6                	ld	s1,104(sp)
    80000740:	7906                	ld	s2,96(sp)
    80000742:	69e6                	ld	s3,88(sp)
    80000744:	6a46                	ld	s4,80(sp)
    80000746:	6aa6                	ld	s5,72(sp)
    80000748:	6b06                	ld	s6,64(sp)
    8000074a:	7be2                	ld	s7,56(sp)
    8000074c:	7c42                	ld	s8,48(sp)
    8000074e:	7ca2                	ld	s9,40(sp)
    80000750:	7d02                	ld	s10,32(sp)
    80000752:	6de2                	ld	s11,24(sp)
    80000754:	6129                	addi	sp,sp,192
    80000756:	8082                	ret
    release(&pr.lock);
    80000758:	00010517          	auipc	a0,0x10
    8000075c:	3a050513          	addi	a0,a0,928 # 80010af8 <pr>
    80000760:	00000097          	auipc	ra,0x0
    80000764:	52a080e7          	jalr	1322(ra) # 80000c8a <release>
}
    80000768:	bfc9                	j	8000073a <printf+0x1b0>

000000008000076a <printfinit>:
    ;
}

void
printfinit(void)
{
    8000076a:	1101                	addi	sp,sp,-32
    8000076c:	ec06                	sd	ra,24(sp)
    8000076e:	e822                	sd	s0,16(sp)
    80000770:	e426                	sd	s1,8(sp)
    80000772:	1000                	addi	s0,sp,32
  initlock(&pr.lock, "pr");
    80000774:	00010497          	auipc	s1,0x10
    80000778:	38448493          	addi	s1,s1,900 # 80010af8 <pr>
    8000077c:	00008597          	auipc	a1,0x8
    80000780:	8bc58593          	addi	a1,a1,-1860 # 80008038 <etext+0x38>
    80000784:	8526                	mv	a0,s1
    80000786:	00000097          	auipc	ra,0x0
    8000078a:	3c0080e7          	jalr	960(ra) # 80000b46 <initlock>
  pr.locking = 1;
    8000078e:	4785                	li	a5,1
    80000790:	cc9c                	sw	a5,24(s1)
}
    80000792:	60e2                	ld	ra,24(sp)
    80000794:	6442                	ld	s0,16(sp)
    80000796:	64a2                	ld	s1,8(sp)
    80000798:	6105                	addi	sp,sp,32
    8000079a:	8082                	ret

000000008000079c <uartinit>:

void uartstart();

void
uartinit(void)
{
    8000079c:	1141                	addi	sp,sp,-16
    8000079e:	e406                	sd	ra,8(sp)
    800007a0:	e022                	sd	s0,0(sp)
    800007a2:	0800                	addi	s0,sp,16
  // disable interrupts.
  WriteReg(IER, 0x00);
    800007a4:	100007b7          	lui	a5,0x10000
    800007a8:	000780a3          	sb	zero,1(a5) # 10000001 <_entry-0x6fffffff>

  // special mode to set baud rate.
  WriteReg(LCR, LCR_BAUD_LATCH);
    800007ac:	f8000713          	li	a4,-128
    800007b0:	00e781a3          	sb	a4,3(a5)

  // LSB for baud rate of 38.4K.
  WriteReg(0, 0x03);
    800007b4:	470d                	li	a4,3
    800007b6:	00e78023          	sb	a4,0(a5)

  // MSB for baud rate of 38.4K.
  WriteReg(1, 0x00);
    800007ba:	000780a3          	sb	zero,1(a5)

  // leave set-baud mode,
  // and set word length to 8 bits, no parity.
  WriteReg(LCR, LCR_EIGHT_BITS);
    800007be:	00e781a3          	sb	a4,3(a5)

  // reset and enable FIFOs.
  WriteReg(FCR, FCR_FIFO_ENABLE | FCR_FIFO_CLEAR);
    800007c2:	469d                	li	a3,7
    800007c4:	00d78123          	sb	a3,2(a5)

  // enable transmit and receive interrupts.
  WriteReg(IER, IER_TX_ENABLE | IER_RX_ENABLE);
    800007c8:	00e780a3          	sb	a4,1(a5)

  initlock(&uart_tx_lock, "uart");
    800007cc:	00008597          	auipc	a1,0x8
    800007d0:	88c58593          	addi	a1,a1,-1908 # 80008058 <digits+0x18>
    800007d4:	00010517          	auipc	a0,0x10
    800007d8:	34450513          	addi	a0,a0,836 # 80010b18 <uart_tx_lock>
    800007dc:	00000097          	auipc	ra,0x0
    800007e0:	36a080e7          	jalr	874(ra) # 80000b46 <initlock>
}
    800007e4:	60a2                	ld	ra,8(sp)
    800007e6:	6402                	ld	s0,0(sp)
    800007e8:	0141                	addi	sp,sp,16
    800007ea:	8082                	ret

00000000800007ec <uartputc_sync>:
// use interrupts, for use by kernel printf() and
// to echo characters. it spins waiting for the uart's
// output register to be empty.
void
uartputc_sync(int c)
{
    800007ec:	1101                	addi	sp,sp,-32
    800007ee:	ec06                	sd	ra,24(sp)
    800007f0:	e822                	sd	s0,16(sp)
    800007f2:	e426                	sd	s1,8(sp)
    800007f4:	1000                	addi	s0,sp,32
    800007f6:	84aa                	mv	s1,a0
  push_off();
    800007f8:	00000097          	auipc	ra,0x0
    800007fc:	392080e7          	jalr	914(ra) # 80000b8a <push_off>

  if(panicked){
    80000800:	00008797          	auipc	a5,0x8
    80000804:	0d07a783          	lw	a5,208(a5) # 800088d0 <panicked>
    for(;;)
      ;
  }

  // wait for Transmit Holding Empty to be set in LSR.
  while((ReadReg(LSR) & LSR_TX_IDLE) == 0)
    80000808:	10000737          	lui	a4,0x10000
  if(panicked){
    8000080c:	c391                	beqz	a5,80000810 <uartputc_sync+0x24>
    for(;;)
    8000080e:	a001                	j	8000080e <uartputc_sync+0x22>
  while((ReadReg(LSR) & LSR_TX_IDLE) == 0)
    80000810:	00574783          	lbu	a5,5(a4) # 10000005 <_entry-0x6ffffffb>
    80000814:	0207f793          	andi	a5,a5,32
    80000818:	dfe5                	beqz	a5,80000810 <uartputc_sync+0x24>
    ;
  WriteReg(THR, c);
    8000081a:	0ff4f513          	zext.b	a0,s1
    8000081e:	100007b7          	lui	a5,0x10000
    80000822:	00a78023          	sb	a0,0(a5) # 10000000 <_entry-0x70000000>

  pop_off();
    80000826:	00000097          	auipc	ra,0x0
    8000082a:	404080e7          	jalr	1028(ra) # 80000c2a <pop_off>
}
    8000082e:	60e2                	ld	ra,24(sp)
    80000830:	6442                	ld	s0,16(sp)
    80000832:	64a2                	ld	s1,8(sp)
    80000834:	6105                	addi	sp,sp,32
    80000836:	8082                	ret

0000000080000838 <uartstart>:
// called from both the top- and bottom-half.
void
uartstart()
{
  while(1){
    if(uart_tx_w == uart_tx_r){
    80000838:	00008797          	auipc	a5,0x8
    8000083c:	0a07b783          	ld	a5,160(a5) # 800088d8 <uart_tx_r>
    80000840:	00008717          	auipc	a4,0x8
    80000844:	0a073703          	ld	a4,160(a4) # 800088e0 <uart_tx_w>
    80000848:	06f70a63          	beq	a4,a5,800008bc <uartstart+0x84>
{
    8000084c:	7139                	addi	sp,sp,-64
    8000084e:	fc06                	sd	ra,56(sp)
    80000850:	f822                	sd	s0,48(sp)
    80000852:	f426                	sd	s1,40(sp)
    80000854:	f04a                	sd	s2,32(sp)
    80000856:	ec4e                	sd	s3,24(sp)
    80000858:	e852                	sd	s4,16(sp)
    8000085a:	e456                	sd	s5,8(sp)
    8000085c:	0080                	addi	s0,sp,64
      // transmit buffer is empty.
      return;
    }
    
    if((ReadReg(LSR) & LSR_TX_IDLE) == 0){
    8000085e:	10000937          	lui	s2,0x10000
      // so we cannot give it another byte.
      // it will interrupt when it's ready for a new byte.
      return;
    }
    
    int c = uart_tx_buf[uart_tx_r % UART_TX_BUF_SIZE];
    80000862:	00010a17          	auipc	s4,0x10
    80000866:	2b6a0a13          	addi	s4,s4,694 # 80010b18 <uart_tx_lock>
    uart_tx_r += 1;
    8000086a:	00008497          	auipc	s1,0x8
    8000086e:	06e48493          	addi	s1,s1,110 # 800088d8 <uart_tx_r>
    if(uart_tx_w == uart_tx_r){
    80000872:	00008997          	auipc	s3,0x8
    80000876:	06e98993          	addi	s3,s3,110 # 800088e0 <uart_tx_w>
    if((ReadReg(LSR) & LSR_TX_IDLE) == 0){
    8000087a:	00594703          	lbu	a4,5(s2) # 10000005 <_entry-0x6ffffffb>
    8000087e:	02077713          	andi	a4,a4,32
    80000882:	c705                	beqz	a4,800008aa <uartstart+0x72>
    int c = uart_tx_buf[uart_tx_r % UART_TX_BUF_SIZE];
    80000884:	01f7f713          	andi	a4,a5,31
    80000888:	9752                	add	a4,a4,s4
    8000088a:	01874a83          	lbu	s5,24(a4)
    uart_tx_r += 1;
    8000088e:	0785                	addi	a5,a5,1
    80000890:	e09c                	sd	a5,0(s1)
    
    // maybe uartputc() is waiting for space in the buffer.
    wakeup(&uart_tx_r);
    80000892:	8526                	mv	a0,s1
    80000894:	00002097          	auipc	ra,0x2
    80000898:	8e8080e7          	jalr	-1816(ra) # 8000217c <wakeup>
    
    WriteReg(THR, c);
    8000089c:	01590023          	sb	s5,0(s2)
    if(uart_tx_w == uart_tx_r){
    800008a0:	609c                	ld	a5,0(s1)
    800008a2:	0009b703          	ld	a4,0(s3)
    800008a6:	fcf71ae3          	bne	a4,a5,8000087a <uartstart+0x42>
  }
}
    800008aa:	70e2                	ld	ra,56(sp)
    800008ac:	7442                	ld	s0,48(sp)
    800008ae:	74a2                	ld	s1,40(sp)
    800008b0:	7902                	ld	s2,32(sp)
    800008b2:	69e2                	ld	s3,24(sp)
    800008b4:	6a42                	ld	s4,16(sp)
    800008b6:	6aa2                	ld	s5,8(sp)
    800008b8:	6121                	addi	sp,sp,64
    800008ba:	8082                	ret
    800008bc:	8082                	ret

00000000800008be <uartputc>:
{
    800008be:	7179                	addi	sp,sp,-48
    800008c0:	f406                	sd	ra,40(sp)
    800008c2:	f022                	sd	s0,32(sp)
    800008c4:	ec26                	sd	s1,24(sp)
    800008c6:	e84a                	sd	s2,16(sp)
    800008c8:	e44e                	sd	s3,8(sp)
    800008ca:	e052                	sd	s4,0(sp)
    800008cc:	1800                	addi	s0,sp,48
    800008ce:	8a2a                	mv	s4,a0
  acquire(&uart_tx_lock);
    800008d0:	00010517          	auipc	a0,0x10
    800008d4:	24850513          	addi	a0,a0,584 # 80010b18 <uart_tx_lock>
    800008d8:	00000097          	auipc	ra,0x0
    800008dc:	2fe080e7          	jalr	766(ra) # 80000bd6 <acquire>
  if(panicked){
    800008e0:	00008797          	auipc	a5,0x8
    800008e4:	ff07a783          	lw	a5,-16(a5) # 800088d0 <panicked>
    800008e8:	e7c9                	bnez	a5,80000972 <uartputc+0xb4>
  while(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    800008ea:	00008717          	auipc	a4,0x8
    800008ee:	ff673703          	ld	a4,-10(a4) # 800088e0 <uart_tx_w>
    800008f2:	00008797          	auipc	a5,0x8
    800008f6:	fe67b783          	ld	a5,-26(a5) # 800088d8 <uart_tx_r>
    800008fa:	02078793          	addi	a5,a5,32
    sleep(&uart_tx_r, &uart_tx_lock);
    800008fe:	00010997          	auipc	s3,0x10
    80000902:	21a98993          	addi	s3,s3,538 # 80010b18 <uart_tx_lock>
    80000906:	00008497          	auipc	s1,0x8
    8000090a:	fd248493          	addi	s1,s1,-46 # 800088d8 <uart_tx_r>
  while(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    8000090e:	00008917          	auipc	s2,0x8
    80000912:	fd290913          	addi	s2,s2,-46 # 800088e0 <uart_tx_w>
    80000916:	00e79f63          	bne	a5,a4,80000934 <uartputc+0x76>
    sleep(&uart_tx_r, &uart_tx_lock);
    8000091a:	85ce                	mv	a1,s3
    8000091c:	8526                	mv	a0,s1
    8000091e:	00001097          	auipc	ra,0x1
    80000922:	7fa080e7          	jalr	2042(ra) # 80002118 <sleep>
  while(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    80000926:	00093703          	ld	a4,0(s2)
    8000092a:	609c                	ld	a5,0(s1)
    8000092c:	02078793          	addi	a5,a5,32
    80000930:	fee785e3          	beq	a5,a4,8000091a <uartputc+0x5c>
  uart_tx_buf[uart_tx_w % UART_TX_BUF_SIZE] = c;
    80000934:	00010497          	auipc	s1,0x10
    80000938:	1e448493          	addi	s1,s1,484 # 80010b18 <uart_tx_lock>
    8000093c:	01f77793          	andi	a5,a4,31
    80000940:	97a6                	add	a5,a5,s1
    80000942:	01478c23          	sb	s4,24(a5)
  uart_tx_w += 1;
    80000946:	0705                	addi	a4,a4,1
    80000948:	00008797          	auipc	a5,0x8
    8000094c:	f8e7bc23          	sd	a4,-104(a5) # 800088e0 <uart_tx_w>
  uartstart();
    80000950:	00000097          	auipc	ra,0x0
    80000954:	ee8080e7          	jalr	-280(ra) # 80000838 <uartstart>
  release(&uart_tx_lock);
    80000958:	8526                	mv	a0,s1
    8000095a:	00000097          	auipc	ra,0x0
    8000095e:	330080e7          	jalr	816(ra) # 80000c8a <release>
}
    80000962:	70a2                	ld	ra,40(sp)
    80000964:	7402                	ld	s0,32(sp)
    80000966:	64e2                	ld	s1,24(sp)
    80000968:	6942                	ld	s2,16(sp)
    8000096a:	69a2                	ld	s3,8(sp)
    8000096c:	6a02                	ld	s4,0(sp)
    8000096e:	6145                	addi	sp,sp,48
    80000970:	8082                	ret
    for(;;)
    80000972:	a001                	j	80000972 <uartputc+0xb4>

0000000080000974 <uartgetc>:

// read one input character from the UART.
// return -1 if none is waiting.
int
uartgetc(void)
{
    80000974:	1141                	addi	sp,sp,-16
    80000976:	e422                	sd	s0,8(sp)
    80000978:	0800                	addi	s0,sp,16
  if(ReadReg(LSR) & 0x01){
    8000097a:	100007b7          	lui	a5,0x10000
    8000097e:	0057c783          	lbu	a5,5(a5) # 10000005 <_entry-0x6ffffffb>
    80000982:	8b85                	andi	a5,a5,1
    80000984:	cb81                	beqz	a5,80000994 <uartgetc+0x20>
    // input data is ready.
    return ReadReg(RHR);
    80000986:	100007b7          	lui	a5,0x10000
    8000098a:	0007c503          	lbu	a0,0(a5) # 10000000 <_entry-0x70000000>
  } else {
    return -1;
  }
}
    8000098e:	6422                	ld	s0,8(sp)
    80000990:	0141                	addi	sp,sp,16
    80000992:	8082                	ret
    return -1;
    80000994:	557d                	li	a0,-1
    80000996:	bfe5                	j	8000098e <uartgetc+0x1a>

0000000080000998 <uartintr>:
// handle a uart interrupt, raised because input has
// arrived, or the uart is ready for more output, or
// both. called from devintr().
void
uartintr(void)
{
    80000998:	1101                	addi	sp,sp,-32
    8000099a:	ec06                	sd	ra,24(sp)
    8000099c:	e822                	sd	s0,16(sp)
    8000099e:	e426                	sd	s1,8(sp)
    800009a0:	1000                	addi	s0,sp,32
  // read and process incoming characters.
  while(1){
    int c = uartgetc();
    if(c == -1)
    800009a2:	54fd                	li	s1,-1
    800009a4:	a029                	j	800009ae <uartintr+0x16>
      break;
    consoleintr(c);
    800009a6:	00000097          	auipc	ra,0x0
    800009aa:	918080e7          	jalr	-1768(ra) # 800002be <consoleintr>
    int c = uartgetc();
    800009ae:	00000097          	auipc	ra,0x0
    800009b2:	fc6080e7          	jalr	-58(ra) # 80000974 <uartgetc>
    if(c == -1)
    800009b6:	fe9518e3          	bne	a0,s1,800009a6 <uartintr+0xe>
  }

  // send buffered characters.
  acquire(&uart_tx_lock);
    800009ba:	00010497          	auipc	s1,0x10
    800009be:	15e48493          	addi	s1,s1,350 # 80010b18 <uart_tx_lock>
    800009c2:	8526                	mv	a0,s1
    800009c4:	00000097          	auipc	ra,0x0
    800009c8:	212080e7          	jalr	530(ra) # 80000bd6 <acquire>
  uartstart();
    800009cc:	00000097          	auipc	ra,0x0
    800009d0:	e6c080e7          	jalr	-404(ra) # 80000838 <uartstart>
  release(&uart_tx_lock);
    800009d4:	8526                	mv	a0,s1
    800009d6:	00000097          	auipc	ra,0x0
    800009da:	2b4080e7          	jalr	692(ra) # 80000c8a <release>
}
    800009de:	60e2                	ld	ra,24(sp)
    800009e0:	6442                	ld	s0,16(sp)
    800009e2:	64a2                	ld	s1,8(sp)
    800009e4:	6105                	addi	sp,sp,32
    800009e6:	8082                	ret

00000000800009e8 <kfree>:
// which normally should have been returned by a
// call to kalloc().  (The exception is when
// initializing the allocator; see kinit above.)
void
kfree(void *pa)
{
    800009e8:	1101                	addi	sp,sp,-32
    800009ea:	ec06                	sd	ra,24(sp)
    800009ec:	e822                	sd	s0,16(sp)
    800009ee:	e426                	sd	s1,8(sp)
    800009f0:	e04a                	sd	s2,0(sp)
    800009f2:	1000                	addi	s0,sp,32
  struct run *r;

  if(((uint64)pa % PGSIZE) != 0 || (char*)pa < end || (uint64)pa >= PHYSTOP)
    800009f4:	03451793          	slli	a5,a0,0x34
    800009f8:	ebb9                	bnez	a5,80000a4e <kfree+0x66>
    800009fa:	84aa                	mv	s1,a0
    800009fc:	00022797          	auipc	a5,0x22
    80000a00:	18478793          	addi	a5,a5,388 # 80022b80 <end>
    80000a04:	04f56563          	bltu	a0,a5,80000a4e <kfree+0x66>
    80000a08:	47c5                	li	a5,17
    80000a0a:	07ee                	slli	a5,a5,0x1b
    80000a0c:	04f57163          	bgeu	a0,a5,80000a4e <kfree+0x66>
    panic("kfree");

  // Fill with junk to catch dangling refs.
  memset(pa, 1, PGSIZE);
    80000a10:	6605                	lui	a2,0x1
    80000a12:	4585                	li	a1,1
    80000a14:	00000097          	auipc	ra,0x0
    80000a18:	2be080e7          	jalr	702(ra) # 80000cd2 <memset>

  r = (struct run*)pa;

  acquire(&kmem.lock);
    80000a1c:	00010917          	auipc	s2,0x10
    80000a20:	13490913          	addi	s2,s2,308 # 80010b50 <kmem>
    80000a24:	854a                	mv	a0,s2
    80000a26:	00000097          	auipc	ra,0x0
    80000a2a:	1b0080e7          	jalr	432(ra) # 80000bd6 <acquire>
  r->next = kmem.freelist;
    80000a2e:	01893783          	ld	a5,24(s2)
    80000a32:	e09c                	sd	a5,0(s1)
  kmem.freelist = r;
    80000a34:	00993c23          	sd	s1,24(s2)
  release(&kmem.lock);
    80000a38:	854a                	mv	a0,s2
    80000a3a:	00000097          	auipc	ra,0x0
    80000a3e:	250080e7          	jalr	592(ra) # 80000c8a <release>
}
    80000a42:	60e2                	ld	ra,24(sp)
    80000a44:	6442                	ld	s0,16(sp)
    80000a46:	64a2                	ld	s1,8(sp)
    80000a48:	6902                	ld	s2,0(sp)
    80000a4a:	6105                	addi	sp,sp,32
    80000a4c:	8082                	ret
    panic("kfree");
    80000a4e:	00007517          	auipc	a0,0x7
    80000a52:	61250513          	addi	a0,a0,1554 # 80008060 <digits+0x20>
    80000a56:	00000097          	auipc	ra,0x0
    80000a5a:	aea080e7          	jalr	-1302(ra) # 80000540 <panic>

0000000080000a5e <freerange>:
{
    80000a5e:	7179                	addi	sp,sp,-48
    80000a60:	f406                	sd	ra,40(sp)
    80000a62:	f022                	sd	s0,32(sp)
    80000a64:	ec26                	sd	s1,24(sp)
    80000a66:	e84a                	sd	s2,16(sp)
    80000a68:	e44e                	sd	s3,8(sp)
    80000a6a:	e052                	sd	s4,0(sp)
    80000a6c:	1800                	addi	s0,sp,48
  p = (char*)PGROUNDUP((uint64)pa_start);
    80000a6e:	6785                	lui	a5,0x1
    80000a70:	fff78713          	addi	a4,a5,-1 # fff <_entry-0x7ffff001>
    80000a74:	00e504b3          	add	s1,a0,a4
    80000a78:	777d                	lui	a4,0xfffff
    80000a7a:	8cf9                	and	s1,s1,a4
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000a7c:	94be                	add	s1,s1,a5
    80000a7e:	0095ee63          	bltu	a1,s1,80000a9a <freerange+0x3c>
    80000a82:	892e                	mv	s2,a1
    kfree(p);
    80000a84:	7a7d                	lui	s4,0xfffff
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000a86:	6985                	lui	s3,0x1
    kfree(p);
    80000a88:	01448533          	add	a0,s1,s4
    80000a8c:	00000097          	auipc	ra,0x0
    80000a90:	f5c080e7          	jalr	-164(ra) # 800009e8 <kfree>
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000a94:	94ce                	add	s1,s1,s3
    80000a96:	fe9979e3          	bgeu	s2,s1,80000a88 <freerange+0x2a>
}
    80000a9a:	70a2                	ld	ra,40(sp)
    80000a9c:	7402                	ld	s0,32(sp)
    80000a9e:	64e2                	ld	s1,24(sp)
    80000aa0:	6942                	ld	s2,16(sp)
    80000aa2:	69a2                	ld	s3,8(sp)
    80000aa4:	6a02                	ld	s4,0(sp)
    80000aa6:	6145                	addi	sp,sp,48
    80000aa8:	8082                	ret

0000000080000aaa <kinit>:
{
    80000aaa:	1141                	addi	sp,sp,-16
    80000aac:	e406                	sd	ra,8(sp)
    80000aae:	e022                	sd	s0,0(sp)
    80000ab0:	0800                	addi	s0,sp,16
  initlock(&kmem.lock, "kmem");
    80000ab2:	00007597          	auipc	a1,0x7
    80000ab6:	5b658593          	addi	a1,a1,1462 # 80008068 <digits+0x28>
    80000aba:	00010517          	auipc	a0,0x10
    80000abe:	09650513          	addi	a0,a0,150 # 80010b50 <kmem>
    80000ac2:	00000097          	auipc	ra,0x0
    80000ac6:	084080e7          	jalr	132(ra) # 80000b46 <initlock>
  freerange(end, (void*)PHYSTOP);
    80000aca:	45c5                	li	a1,17
    80000acc:	05ee                	slli	a1,a1,0x1b
    80000ace:	00022517          	auipc	a0,0x22
    80000ad2:	0b250513          	addi	a0,a0,178 # 80022b80 <end>
    80000ad6:	00000097          	auipc	ra,0x0
    80000ada:	f88080e7          	jalr	-120(ra) # 80000a5e <freerange>
}
    80000ade:	60a2                	ld	ra,8(sp)
    80000ae0:	6402                	ld	s0,0(sp)
    80000ae2:	0141                	addi	sp,sp,16
    80000ae4:	8082                	ret

0000000080000ae6 <kalloc>:
// Allocate one 4096-byte page of physical memory.
// Returns a pointer that the kernel can use.
// Returns 0 if the memory cannot be allocated.
void *
kalloc(void)
{
    80000ae6:	1101                	addi	sp,sp,-32
    80000ae8:	ec06                	sd	ra,24(sp)
    80000aea:	e822                	sd	s0,16(sp)
    80000aec:	e426                	sd	s1,8(sp)
    80000aee:	1000                	addi	s0,sp,32
  struct run *r;

  acquire(&kmem.lock);
    80000af0:	00010497          	auipc	s1,0x10
    80000af4:	06048493          	addi	s1,s1,96 # 80010b50 <kmem>
    80000af8:	8526                	mv	a0,s1
    80000afa:	00000097          	auipc	ra,0x0
    80000afe:	0dc080e7          	jalr	220(ra) # 80000bd6 <acquire>
  r = kmem.freelist;
    80000b02:	6c84                	ld	s1,24(s1)
  if(r)
    80000b04:	c885                	beqz	s1,80000b34 <kalloc+0x4e>
    kmem.freelist = r->next;
    80000b06:	609c                	ld	a5,0(s1)
    80000b08:	00010517          	auipc	a0,0x10
    80000b0c:	04850513          	addi	a0,a0,72 # 80010b50 <kmem>
    80000b10:	ed1c                	sd	a5,24(a0)
  release(&kmem.lock);
    80000b12:	00000097          	auipc	ra,0x0
    80000b16:	178080e7          	jalr	376(ra) # 80000c8a <release>

  if(r)
    memset((char*)r, 5, PGSIZE); // fill with junk
    80000b1a:	6605                	lui	a2,0x1
    80000b1c:	4595                	li	a1,5
    80000b1e:	8526                	mv	a0,s1
    80000b20:	00000097          	auipc	ra,0x0
    80000b24:	1b2080e7          	jalr	434(ra) # 80000cd2 <memset>
  return (void*)r;
}
    80000b28:	8526                	mv	a0,s1
    80000b2a:	60e2                	ld	ra,24(sp)
    80000b2c:	6442                	ld	s0,16(sp)
    80000b2e:	64a2                	ld	s1,8(sp)
    80000b30:	6105                	addi	sp,sp,32
    80000b32:	8082                	ret
  release(&kmem.lock);
    80000b34:	00010517          	auipc	a0,0x10
    80000b38:	01c50513          	addi	a0,a0,28 # 80010b50 <kmem>
    80000b3c:	00000097          	auipc	ra,0x0
    80000b40:	14e080e7          	jalr	334(ra) # 80000c8a <release>
  if(r)
    80000b44:	b7d5                	j	80000b28 <kalloc+0x42>

0000000080000b46 <initlock>:
#include "proc.h"
#include "defs.h"

void
initlock(struct spinlock *lk, char *name)
{
    80000b46:	1141                	addi	sp,sp,-16
    80000b48:	e422                	sd	s0,8(sp)
    80000b4a:	0800                	addi	s0,sp,16
  lk->name = name;
    80000b4c:	e50c                	sd	a1,8(a0)
  lk->locked = 0;
    80000b4e:	00052023          	sw	zero,0(a0)
  lk->cpu = 0;
    80000b52:	00053823          	sd	zero,16(a0)
}
    80000b56:	6422                	ld	s0,8(sp)
    80000b58:	0141                	addi	sp,sp,16
    80000b5a:	8082                	ret

0000000080000b5c <holding>:
// Interrupts must be off.
int
holding(struct spinlock *lk)
{
  int r;
  r = (lk->locked && lk->cpu == mycpu());
    80000b5c:	411c                	lw	a5,0(a0)
    80000b5e:	e399                	bnez	a5,80000b64 <holding+0x8>
    80000b60:	4501                	li	a0,0
  return r;
}
    80000b62:	8082                	ret
{
    80000b64:	1101                	addi	sp,sp,-32
    80000b66:	ec06                	sd	ra,24(sp)
    80000b68:	e822                	sd	s0,16(sp)
    80000b6a:	e426                	sd	s1,8(sp)
    80000b6c:	1000                	addi	s0,sp,32
  r = (lk->locked && lk->cpu == mycpu());
    80000b6e:	6904                	ld	s1,16(a0)
    80000b70:	00001097          	auipc	ra,0x1
    80000b74:	e20080e7          	jalr	-480(ra) # 80001990 <mycpu>
    80000b78:	40a48533          	sub	a0,s1,a0
    80000b7c:	00153513          	seqz	a0,a0
}
    80000b80:	60e2                	ld	ra,24(sp)
    80000b82:	6442                	ld	s0,16(sp)
    80000b84:	64a2                	ld	s1,8(sp)
    80000b86:	6105                	addi	sp,sp,32
    80000b88:	8082                	ret

0000000080000b8a <push_off>:
// it takes two pop_off()s to undo two push_off()s.  Also, if interrupts
// are initially off, then push_off, pop_off leaves them off.

void
push_off(void)
{
    80000b8a:	1101                	addi	sp,sp,-32
    80000b8c:	ec06                	sd	ra,24(sp)
    80000b8e:	e822                	sd	s0,16(sp)
    80000b90:	e426                	sd	s1,8(sp)
    80000b92:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000b94:	100024f3          	csrr	s1,sstatus
    80000b98:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    80000b9c:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80000b9e:	10079073          	csrw	sstatus,a5
  int old = intr_get();

  intr_off();
  if(mycpu()->noff == 0)
    80000ba2:	00001097          	auipc	ra,0x1
    80000ba6:	dee080e7          	jalr	-530(ra) # 80001990 <mycpu>
    80000baa:	5d3c                	lw	a5,120(a0)
    80000bac:	cf89                	beqz	a5,80000bc6 <push_off+0x3c>
    mycpu()->intena = old;
  mycpu()->noff += 1;
    80000bae:	00001097          	auipc	ra,0x1
    80000bb2:	de2080e7          	jalr	-542(ra) # 80001990 <mycpu>
    80000bb6:	5d3c                	lw	a5,120(a0)
    80000bb8:	2785                	addiw	a5,a5,1
    80000bba:	dd3c                	sw	a5,120(a0)
}
    80000bbc:	60e2                	ld	ra,24(sp)
    80000bbe:	6442                	ld	s0,16(sp)
    80000bc0:	64a2                	ld	s1,8(sp)
    80000bc2:	6105                	addi	sp,sp,32
    80000bc4:	8082                	ret
    mycpu()->intena = old;
    80000bc6:	00001097          	auipc	ra,0x1
    80000bca:	dca080e7          	jalr	-566(ra) # 80001990 <mycpu>
  return (x & SSTATUS_SIE) != 0;
    80000bce:	8085                	srli	s1,s1,0x1
    80000bd0:	8885                	andi	s1,s1,1
    80000bd2:	dd64                	sw	s1,124(a0)
    80000bd4:	bfe9                	j	80000bae <push_off+0x24>

0000000080000bd6 <acquire>:
{
    80000bd6:	1101                	addi	sp,sp,-32
    80000bd8:	ec06                	sd	ra,24(sp)
    80000bda:	e822                	sd	s0,16(sp)
    80000bdc:	e426                	sd	s1,8(sp)
    80000bde:	1000                	addi	s0,sp,32
    80000be0:	84aa                	mv	s1,a0
  push_off(); // disable interrupts to avoid deadlock.
    80000be2:	00000097          	auipc	ra,0x0
    80000be6:	fa8080e7          	jalr	-88(ra) # 80000b8a <push_off>
  if(holding(lk))
    80000bea:	8526                	mv	a0,s1
    80000bec:	00000097          	auipc	ra,0x0
    80000bf0:	f70080e7          	jalr	-144(ra) # 80000b5c <holding>
  while(__sync_lock_test_and_set(&lk->locked, 1) != 0)
    80000bf4:	4705                	li	a4,1
  if(holding(lk))
    80000bf6:	e115                	bnez	a0,80000c1a <acquire+0x44>
  while(__sync_lock_test_and_set(&lk->locked, 1) != 0)
    80000bf8:	87ba                	mv	a5,a4
    80000bfa:	0cf4a7af          	amoswap.w.aq	a5,a5,(s1)
    80000bfe:	2781                	sext.w	a5,a5
    80000c00:	ffe5                	bnez	a5,80000bf8 <acquire+0x22>
  __sync_synchronize();
    80000c02:	0ff0000f          	fence
  lk->cpu = mycpu();
    80000c06:	00001097          	auipc	ra,0x1
    80000c0a:	d8a080e7          	jalr	-630(ra) # 80001990 <mycpu>
    80000c0e:	e888                	sd	a0,16(s1)
}
    80000c10:	60e2                	ld	ra,24(sp)
    80000c12:	6442                	ld	s0,16(sp)
    80000c14:	64a2                	ld	s1,8(sp)
    80000c16:	6105                	addi	sp,sp,32
    80000c18:	8082                	ret
    panic("acquire");
    80000c1a:	00007517          	auipc	a0,0x7
    80000c1e:	45650513          	addi	a0,a0,1110 # 80008070 <digits+0x30>
    80000c22:	00000097          	auipc	ra,0x0
    80000c26:	91e080e7          	jalr	-1762(ra) # 80000540 <panic>

0000000080000c2a <pop_off>:

void
pop_off(void)
{
    80000c2a:	1141                	addi	sp,sp,-16
    80000c2c:	e406                	sd	ra,8(sp)
    80000c2e:	e022                	sd	s0,0(sp)
    80000c30:	0800                	addi	s0,sp,16
  struct cpu *c = mycpu();
    80000c32:	00001097          	auipc	ra,0x1
    80000c36:	d5e080e7          	jalr	-674(ra) # 80001990 <mycpu>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000c3a:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80000c3e:	8b89                	andi	a5,a5,2
  if(intr_get())
    80000c40:	e78d                	bnez	a5,80000c6a <pop_off+0x40>
    panic("pop_off - interruptible");
  if(c->noff < 1)
    80000c42:	5d3c                	lw	a5,120(a0)
    80000c44:	02f05b63          	blez	a5,80000c7a <pop_off+0x50>
    panic("pop_off");
  c->noff -= 1;
    80000c48:	37fd                	addiw	a5,a5,-1
    80000c4a:	0007871b          	sext.w	a4,a5
    80000c4e:	dd3c                	sw	a5,120(a0)
  if(c->noff == 0 && c->intena)
    80000c50:	eb09                	bnez	a4,80000c62 <pop_off+0x38>
    80000c52:	5d7c                	lw	a5,124(a0)
    80000c54:	c799                	beqz	a5,80000c62 <pop_off+0x38>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000c56:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80000c5a:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80000c5e:	10079073          	csrw	sstatus,a5
    intr_on();
}
    80000c62:	60a2                	ld	ra,8(sp)
    80000c64:	6402                	ld	s0,0(sp)
    80000c66:	0141                	addi	sp,sp,16
    80000c68:	8082                	ret
    panic("pop_off - interruptible");
    80000c6a:	00007517          	auipc	a0,0x7
    80000c6e:	40e50513          	addi	a0,a0,1038 # 80008078 <digits+0x38>
    80000c72:	00000097          	auipc	ra,0x0
    80000c76:	8ce080e7          	jalr	-1842(ra) # 80000540 <panic>
    panic("pop_off");
    80000c7a:	00007517          	auipc	a0,0x7
    80000c7e:	41650513          	addi	a0,a0,1046 # 80008090 <digits+0x50>
    80000c82:	00000097          	auipc	ra,0x0
    80000c86:	8be080e7          	jalr	-1858(ra) # 80000540 <panic>

0000000080000c8a <release>:
{
    80000c8a:	1101                	addi	sp,sp,-32
    80000c8c:	ec06                	sd	ra,24(sp)
    80000c8e:	e822                	sd	s0,16(sp)
    80000c90:	e426                	sd	s1,8(sp)
    80000c92:	1000                	addi	s0,sp,32
    80000c94:	84aa                	mv	s1,a0
  if(!holding(lk))
    80000c96:	00000097          	auipc	ra,0x0
    80000c9a:	ec6080e7          	jalr	-314(ra) # 80000b5c <holding>
    80000c9e:	c115                	beqz	a0,80000cc2 <release+0x38>
  lk->cpu = 0;
    80000ca0:	0004b823          	sd	zero,16(s1)
  __sync_synchronize();
    80000ca4:	0ff0000f          	fence
  __sync_lock_release(&lk->locked);
    80000ca8:	0f50000f          	fence	iorw,ow
    80000cac:	0804a02f          	amoswap.w	zero,zero,(s1)
  pop_off();
    80000cb0:	00000097          	auipc	ra,0x0
    80000cb4:	f7a080e7          	jalr	-134(ra) # 80000c2a <pop_off>
}
    80000cb8:	60e2                	ld	ra,24(sp)
    80000cba:	6442                	ld	s0,16(sp)
    80000cbc:	64a2                	ld	s1,8(sp)
    80000cbe:	6105                	addi	sp,sp,32
    80000cc0:	8082                	ret
    panic("release");
    80000cc2:	00007517          	auipc	a0,0x7
    80000cc6:	3d650513          	addi	a0,a0,982 # 80008098 <digits+0x58>
    80000cca:	00000097          	auipc	ra,0x0
    80000cce:	876080e7          	jalr	-1930(ra) # 80000540 <panic>

0000000080000cd2 <memset>:
#include "types.h"

void*
memset(void *dst, int c, uint n)
{
    80000cd2:	1141                	addi	sp,sp,-16
    80000cd4:	e422                	sd	s0,8(sp)
    80000cd6:	0800                	addi	s0,sp,16
  char *cdst = (char *) dst;
  int i;
  for(i = 0; i < n; i++){
    80000cd8:	ca19                	beqz	a2,80000cee <memset+0x1c>
    80000cda:	87aa                	mv	a5,a0
    80000cdc:	1602                	slli	a2,a2,0x20
    80000cde:	9201                	srli	a2,a2,0x20
    80000ce0:	00a60733          	add	a4,a2,a0
    cdst[i] = c;
    80000ce4:	00b78023          	sb	a1,0(a5)
  for(i = 0; i < n; i++){
    80000ce8:	0785                	addi	a5,a5,1
    80000cea:	fee79de3          	bne	a5,a4,80000ce4 <memset+0x12>
  }
  return dst;
}
    80000cee:	6422                	ld	s0,8(sp)
    80000cf0:	0141                	addi	sp,sp,16
    80000cf2:	8082                	ret

0000000080000cf4 <memcmp>:

int
memcmp(const void *v1, const void *v2, uint n)
{
    80000cf4:	1141                	addi	sp,sp,-16
    80000cf6:	e422                	sd	s0,8(sp)
    80000cf8:	0800                	addi	s0,sp,16
  const uchar *s1, *s2;

  s1 = v1;
  s2 = v2;
  while(n-- > 0){
    80000cfa:	ca05                	beqz	a2,80000d2a <memcmp+0x36>
    80000cfc:	fff6069b          	addiw	a3,a2,-1 # fff <_entry-0x7ffff001>
    80000d00:	1682                	slli	a3,a3,0x20
    80000d02:	9281                	srli	a3,a3,0x20
    80000d04:	0685                	addi	a3,a3,1
    80000d06:	96aa                	add	a3,a3,a0
    if(*s1 != *s2)
    80000d08:	00054783          	lbu	a5,0(a0)
    80000d0c:	0005c703          	lbu	a4,0(a1)
    80000d10:	00e79863          	bne	a5,a4,80000d20 <memcmp+0x2c>
      return *s1 - *s2;
    s1++, s2++;
    80000d14:	0505                	addi	a0,a0,1
    80000d16:	0585                	addi	a1,a1,1
  while(n-- > 0){
    80000d18:	fed518e3          	bne	a0,a3,80000d08 <memcmp+0x14>
  }

  return 0;
    80000d1c:	4501                	li	a0,0
    80000d1e:	a019                	j	80000d24 <memcmp+0x30>
      return *s1 - *s2;
    80000d20:	40e7853b          	subw	a0,a5,a4
}
    80000d24:	6422                	ld	s0,8(sp)
    80000d26:	0141                	addi	sp,sp,16
    80000d28:	8082                	ret
  return 0;
    80000d2a:	4501                	li	a0,0
    80000d2c:	bfe5                	j	80000d24 <memcmp+0x30>

0000000080000d2e <memmove>:

void*
memmove(void *dst, const void *src, uint n)
{
    80000d2e:	1141                	addi	sp,sp,-16
    80000d30:	e422                	sd	s0,8(sp)
    80000d32:	0800                	addi	s0,sp,16
  const char *s;
  char *d;

  if(n == 0)
    80000d34:	c205                	beqz	a2,80000d54 <memmove+0x26>
    return dst;
  
  s = src;
  d = dst;
  if(s < d && s + n > d){
    80000d36:	02a5e263          	bltu	a1,a0,80000d5a <memmove+0x2c>
    s += n;
    d += n;
    while(n-- > 0)
      *--d = *--s;
  } else
    while(n-- > 0)
    80000d3a:	1602                	slli	a2,a2,0x20
    80000d3c:	9201                	srli	a2,a2,0x20
    80000d3e:	00c587b3          	add	a5,a1,a2
{
    80000d42:	872a                	mv	a4,a0
      *d++ = *s++;
    80000d44:	0585                	addi	a1,a1,1
    80000d46:	0705                	addi	a4,a4,1 # fffffffffffff001 <end+0xffffffff7ffdc481>
    80000d48:	fff5c683          	lbu	a3,-1(a1)
    80000d4c:	fed70fa3          	sb	a3,-1(a4)
    while(n-- > 0)
    80000d50:	fef59ae3          	bne	a1,a5,80000d44 <memmove+0x16>

  return dst;
}
    80000d54:	6422                	ld	s0,8(sp)
    80000d56:	0141                	addi	sp,sp,16
    80000d58:	8082                	ret
  if(s < d && s + n > d){
    80000d5a:	02061693          	slli	a3,a2,0x20
    80000d5e:	9281                	srli	a3,a3,0x20
    80000d60:	00d58733          	add	a4,a1,a3
    80000d64:	fce57be3          	bgeu	a0,a4,80000d3a <memmove+0xc>
    d += n;
    80000d68:	96aa                	add	a3,a3,a0
    while(n-- > 0)
    80000d6a:	fff6079b          	addiw	a5,a2,-1
    80000d6e:	1782                	slli	a5,a5,0x20
    80000d70:	9381                	srli	a5,a5,0x20
    80000d72:	fff7c793          	not	a5,a5
    80000d76:	97ba                	add	a5,a5,a4
      *--d = *--s;
    80000d78:	177d                	addi	a4,a4,-1
    80000d7a:	16fd                	addi	a3,a3,-1
    80000d7c:	00074603          	lbu	a2,0(a4)
    80000d80:	00c68023          	sb	a2,0(a3)
    while(n-- > 0)
    80000d84:	fee79ae3          	bne	a5,a4,80000d78 <memmove+0x4a>
    80000d88:	b7f1                	j	80000d54 <memmove+0x26>

0000000080000d8a <memcpy>:

// memcpy exists to placate GCC.  Use memmove.
void*
memcpy(void *dst, const void *src, uint n)
{
    80000d8a:	1141                	addi	sp,sp,-16
    80000d8c:	e406                	sd	ra,8(sp)
    80000d8e:	e022                	sd	s0,0(sp)
    80000d90:	0800                	addi	s0,sp,16
  return memmove(dst, src, n);
    80000d92:	00000097          	auipc	ra,0x0
    80000d96:	f9c080e7          	jalr	-100(ra) # 80000d2e <memmove>
}
    80000d9a:	60a2                	ld	ra,8(sp)
    80000d9c:	6402                	ld	s0,0(sp)
    80000d9e:	0141                	addi	sp,sp,16
    80000da0:	8082                	ret

0000000080000da2 <strncmp>:

int
strncmp(const char *p, const char *q, uint n)
{
    80000da2:	1141                	addi	sp,sp,-16
    80000da4:	e422                	sd	s0,8(sp)
    80000da6:	0800                	addi	s0,sp,16
  while(n > 0 && *p && *p == *q)
    80000da8:	ce11                	beqz	a2,80000dc4 <strncmp+0x22>
    80000daa:	00054783          	lbu	a5,0(a0)
    80000dae:	cf89                	beqz	a5,80000dc8 <strncmp+0x26>
    80000db0:	0005c703          	lbu	a4,0(a1)
    80000db4:	00f71a63          	bne	a4,a5,80000dc8 <strncmp+0x26>
    n--, p++, q++;
    80000db8:	367d                	addiw	a2,a2,-1
    80000dba:	0505                	addi	a0,a0,1
    80000dbc:	0585                	addi	a1,a1,1
  while(n > 0 && *p && *p == *q)
    80000dbe:	f675                	bnez	a2,80000daa <strncmp+0x8>
  if(n == 0)
    return 0;
    80000dc0:	4501                	li	a0,0
    80000dc2:	a809                	j	80000dd4 <strncmp+0x32>
    80000dc4:	4501                	li	a0,0
    80000dc6:	a039                	j	80000dd4 <strncmp+0x32>
  if(n == 0)
    80000dc8:	ca09                	beqz	a2,80000dda <strncmp+0x38>
  return (uchar)*p - (uchar)*q;
    80000dca:	00054503          	lbu	a0,0(a0)
    80000dce:	0005c783          	lbu	a5,0(a1)
    80000dd2:	9d1d                	subw	a0,a0,a5
}
    80000dd4:	6422                	ld	s0,8(sp)
    80000dd6:	0141                	addi	sp,sp,16
    80000dd8:	8082                	ret
    return 0;
    80000dda:	4501                	li	a0,0
    80000ddc:	bfe5                	j	80000dd4 <strncmp+0x32>

0000000080000dde <strncpy>:

char*
strncpy(char *s, const char *t, int n)
{
    80000dde:	1141                	addi	sp,sp,-16
    80000de0:	e422                	sd	s0,8(sp)
    80000de2:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  while(n-- > 0 && (*s++ = *t++) != 0)
    80000de4:	872a                	mv	a4,a0
    80000de6:	8832                	mv	a6,a2
    80000de8:	367d                	addiw	a2,a2,-1
    80000dea:	01005963          	blez	a6,80000dfc <strncpy+0x1e>
    80000dee:	0705                	addi	a4,a4,1
    80000df0:	0005c783          	lbu	a5,0(a1)
    80000df4:	fef70fa3          	sb	a5,-1(a4)
    80000df8:	0585                	addi	a1,a1,1
    80000dfa:	f7f5                	bnez	a5,80000de6 <strncpy+0x8>
    ;
  while(n-- > 0)
    80000dfc:	86ba                	mv	a3,a4
    80000dfe:	00c05c63          	blez	a2,80000e16 <strncpy+0x38>
    *s++ = 0;
    80000e02:	0685                	addi	a3,a3,1
    80000e04:	fe068fa3          	sb	zero,-1(a3)
  while(n-- > 0)
    80000e08:	40d707bb          	subw	a5,a4,a3
    80000e0c:	37fd                	addiw	a5,a5,-1
    80000e0e:	010787bb          	addw	a5,a5,a6
    80000e12:	fef048e3          	bgtz	a5,80000e02 <strncpy+0x24>
  return os;
}
    80000e16:	6422                	ld	s0,8(sp)
    80000e18:	0141                	addi	sp,sp,16
    80000e1a:	8082                	ret

0000000080000e1c <safestrcpy>:

// Like strncpy but guaranteed to NUL-terminate.
char*
safestrcpy(char *s, const char *t, int n)
{
    80000e1c:	1141                	addi	sp,sp,-16
    80000e1e:	e422                	sd	s0,8(sp)
    80000e20:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  if(n <= 0)
    80000e22:	02c05363          	blez	a2,80000e48 <safestrcpy+0x2c>
    80000e26:	fff6069b          	addiw	a3,a2,-1
    80000e2a:	1682                	slli	a3,a3,0x20
    80000e2c:	9281                	srli	a3,a3,0x20
    80000e2e:	96ae                	add	a3,a3,a1
    80000e30:	87aa                	mv	a5,a0
    return os;
  while(--n > 0 && (*s++ = *t++) != 0)
    80000e32:	00d58963          	beq	a1,a3,80000e44 <safestrcpy+0x28>
    80000e36:	0585                	addi	a1,a1,1
    80000e38:	0785                	addi	a5,a5,1
    80000e3a:	fff5c703          	lbu	a4,-1(a1)
    80000e3e:	fee78fa3          	sb	a4,-1(a5)
    80000e42:	fb65                	bnez	a4,80000e32 <safestrcpy+0x16>
    ;
  *s = 0;
    80000e44:	00078023          	sb	zero,0(a5)
  return os;
}
    80000e48:	6422                	ld	s0,8(sp)
    80000e4a:	0141                	addi	sp,sp,16
    80000e4c:	8082                	ret

0000000080000e4e <strlen>:

int
strlen(const char *s)
{
    80000e4e:	1141                	addi	sp,sp,-16
    80000e50:	e422                	sd	s0,8(sp)
    80000e52:	0800                	addi	s0,sp,16
  int n;

  for(n = 0; s[n]; n++)
    80000e54:	00054783          	lbu	a5,0(a0)
    80000e58:	cf91                	beqz	a5,80000e74 <strlen+0x26>
    80000e5a:	0505                	addi	a0,a0,1
    80000e5c:	87aa                	mv	a5,a0
    80000e5e:	4685                	li	a3,1
    80000e60:	9e89                	subw	a3,a3,a0
    80000e62:	00f6853b          	addw	a0,a3,a5
    80000e66:	0785                	addi	a5,a5,1
    80000e68:	fff7c703          	lbu	a4,-1(a5)
    80000e6c:	fb7d                	bnez	a4,80000e62 <strlen+0x14>
    ;
  return n;
}
    80000e6e:	6422                	ld	s0,8(sp)
    80000e70:	0141                	addi	sp,sp,16
    80000e72:	8082                	ret
  for(n = 0; s[n]; n++)
    80000e74:	4501                	li	a0,0
    80000e76:	bfe5                	j	80000e6e <strlen+0x20>

0000000080000e78 <main>:
volatile static int started = 0;

// start() jumps here in supervisor mode on all CPUs.
void
main()
{
    80000e78:	1141                	addi	sp,sp,-16
    80000e7a:	e406                	sd	ra,8(sp)
    80000e7c:	e022                	sd	s0,0(sp)
    80000e7e:	0800                	addi	s0,sp,16
  if(cpuid() == 0){
    80000e80:	00001097          	auipc	ra,0x1
    80000e84:	b00080e7          	jalr	-1280(ra) # 80001980 <cpuid>
    virtio_disk_init(); // emulated hard disk
    userinit();      // first user process
    __sync_synchronize();
    started = 1;
  } else {
    while(started == 0)
    80000e88:	00008717          	auipc	a4,0x8
    80000e8c:	a6070713          	addi	a4,a4,-1440 # 800088e8 <started>
  if(cpuid() == 0){
    80000e90:	c139                	beqz	a0,80000ed6 <main+0x5e>
    while(started == 0)
    80000e92:	431c                	lw	a5,0(a4)
    80000e94:	2781                	sext.w	a5,a5
    80000e96:	dff5                	beqz	a5,80000e92 <main+0x1a>
      ;
    __sync_synchronize();
    80000e98:	0ff0000f          	fence
    printf("hart %d starting\n", cpuid());
    80000e9c:	00001097          	auipc	ra,0x1
    80000ea0:	ae4080e7          	jalr	-1308(ra) # 80001980 <cpuid>
    80000ea4:	85aa                	mv	a1,a0
    80000ea6:	00007517          	auipc	a0,0x7
    80000eaa:	21250513          	addi	a0,a0,530 # 800080b8 <digits+0x78>
    80000eae:	fffff097          	auipc	ra,0xfffff
    80000eb2:	6dc080e7          	jalr	1756(ra) # 8000058a <printf>
    kvminithart();    // turn on paging
    80000eb6:	00000097          	auipc	ra,0x0
    80000eba:	0d8080e7          	jalr	216(ra) # 80000f8e <kvminithart>
    trapinithart();   // install kernel trap vector
    80000ebe:	00002097          	auipc	ra,0x2
    80000ec2:	a38080e7          	jalr	-1480(ra) # 800028f6 <trapinithart>
    plicinithart();   // ask PLIC for device interrupts
    80000ec6:	00005097          	auipc	ra,0x5
    80000eca:	47a080e7          	jalr	1146(ra) # 80006340 <plicinithart>
  }

  scheduler();        
    80000ece:	00001097          	auipc	ra,0x1
    80000ed2:	014080e7          	jalr	20(ra) # 80001ee2 <scheduler>
    consoleinit();
    80000ed6:	fffff097          	auipc	ra,0xfffff
    80000eda:	57a080e7          	jalr	1402(ra) # 80000450 <consoleinit>
    printfinit();
    80000ede:	00000097          	auipc	ra,0x0
    80000ee2:	88c080e7          	jalr	-1908(ra) # 8000076a <printfinit>
    printf("\n");
    80000ee6:	00007517          	auipc	a0,0x7
    80000eea:	1e250513          	addi	a0,a0,482 # 800080c8 <digits+0x88>
    80000eee:	fffff097          	auipc	ra,0xfffff
    80000ef2:	69c080e7          	jalr	1692(ra) # 8000058a <printf>
    printf("xv6 kernel is booting\n");
    80000ef6:	00007517          	auipc	a0,0x7
    80000efa:	1aa50513          	addi	a0,a0,426 # 800080a0 <digits+0x60>
    80000efe:	fffff097          	auipc	ra,0xfffff
    80000f02:	68c080e7          	jalr	1676(ra) # 8000058a <printf>
    printf("\n");
    80000f06:	00007517          	auipc	a0,0x7
    80000f0a:	1c250513          	addi	a0,a0,450 # 800080c8 <digits+0x88>
    80000f0e:	fffff097          	auipc	ra,0xfffff
    80000f12:	67c080e7          	jalr	1660(ra) # 8000058a <printf>
    kinit();         // physical page allocator
    80000f16:	00000097          	auipc	ra,0x0
    80000f1a:	b94080e7          	jalr	-1132(ra) # 80000aaa <kinit>
    kvminit();       // create kernel page table
    80000f1e:	00000097          	auipc	ra,0x0
    80000f22:	326080e7          	jalr	806(ra) # 80001244 <kvminit>
    kvminithart();   // turn on paging
    80000f26:	00000097          	auipc	ra,0x0
    80000f2a:	068080e7          	jalr	104(ra) # 80000f8e <kvminithart>
    procinit();      // process table
    80000f2e:	00001097          	auipc	ra,0x1
    80000f32:	99e080e7          	jalr	-1634(ra) # 800018cc <procinit>
    trapinit();      // trap vectors
    80000f36:	00002097          	auipc	ra,0x2
    80000f3a:	998080e7          	jalr	-1640(ra) # 800028ce <trapinit>
    trapinithart();  // install kernel trap vector
    80000f3e:	00002097          	auipc	ra,0x2
    80000f42:	9b8080e7          	jalr	-1608(ra) # 800028f6 <trapinithart>
    plicinit();      // set up interrupt controller
    80000f46:	00005097          	auipc	ra,0x5
    80000f4a:	3e4080e7          	jalr	996(ra) # 8000632a <plicinit>
    plicinithart();  // ask PLIC for device interrupts
    80000f4e:	00005097          	auipc	ra,0x5
    80000f52:	3f2080e7          	jalr	1010(ra) # 80006340 <plicinithart>
    binit();         // buffer cache
    80000f56:	00002097          	auipc	ra,0x2
    80000f5a:	590080e7          	jalr	1424(ra) # 800034e6 <binit>
    iinit();         // inode table
    80000f5e:	00003097          	auipc	ra,0x3
    80000f62:	c30080e7          	jalr	-976(ra) # 80003b8e <iinit>
    fileinit();      // file table
    80000f66:	00004097          	auipc	ra,0x4
    80000f6a:	bd6080e7          	jalr	-1066(ra) # 80004b3c <fileinit>
    virtio_disk_init(); // emulated hard disk
    80000f6e:	00005097          	auipc	ra,0x5
    80000f72:	4da080e7          	jalr	1242(ra) # 80006448 <virtio_disk_init>
    userinit();      // first user process
    80000f76:	00001097          	auipc	ra,0x1
    80000f7a:	d4e080e7          	jalr	-690(ra) # 80001cc4 <userinit>
    __sync_synchronize();
    80000f7e:	0ff0000f          	fence
    started = 1;
    80000f82:	4785                	li	a5,1
    80000f84:	00008717          	auipc	a4,0x8
    80000f88:	96f72223          	sw	a5,-1692(a4) # 800088e8 <started>
    80000f8c:	b789                	j	80000ece <main+0x56>

0000000080000f8e <kvminithart>:

// Switch h/w page table register to the kernel's page table,
// and enable paging.
void
kvminithart()
{
    80000f8e:	1141                	addi	sp,sp,-16
    80000f90:	e422                	sd	s0,8(sp)
    80000f92:	0800                	addi	s0,sp,16
// flush the TLB.
static inline void
sfence_vma()
{
  // the zero, zero means flush all TLB entries.
  asm volatile("sfence.vma zero, zero");
    80000f94:	12000073          	sfence.vma
  // wait for any previous writes to the page table memory to finish.
  sfence_vma();

  w_satp(MAKE_SATP(kernel_pagetable));
    80000f98:	00008797          	auipc	a5,0x8
    80000f9c:	9587b783          	ld	a5,-1704(a5) # 800088f0 <kernel_pagetable>
    80000fa0:	83b1                	srli	a5,a5,0xc
    80000fa2:	577d                	li	a4,-1
    80000fa4:	177e                	slli	a4,a4,0x3f
    80000fa6:	8fd9                	or	a5,a5,a4
  asm volatile("csrw satp, %0" : : "r" (x));
    80000fa8:	18079073          	csrw	satp,a5
  asm volatile("sfence.vma zero, zero");
    80000fac:	12000073          	sfence.vma

  // flush stale entries from the TLB.
  sfence_vma();
}
    80000fb0:	6422                	ld	s0,8(sp)
    80000fb2:	0141                	addi	sp,sp,16
    80000fb4:	8082                	ret

0000000080000fb6 <walk>:
//   21..29 -- 9 bits of level-1 index.
//   12..20 -- 9 bits of level-0 index.
//    0..11 -- 12 bits of byte offset within the page.
pte_t *
walk(pagetable_t pagetable, uint64 va, int alloc)
{
    80000fb6:	7139                	addi	sp,sp,-64
    80000fb8:	fc06                	sd	ra,56(sp)
    80000fba:	f822                	sd	s0,48(sp)
    80000fbc:	f426                	sd	s1,40(sp)
    80000fbe:	f04a                	sd	s2,32(sp)
    80000fc0:	ec4e                	sd	s3,24(sp)
    80000fc2:	e852                	sd	s4,16(sp)
    80000fc4:	e456                	sd	s5,8(sp)
    80000fc6:	e05a                	sd	s6,0(sp)
    80000fc8:	0080                	addi	s0,sp,64
    80000fca:	84aa                	mv	s1,a0
    80000fcc:	89ae                	mv	s3,a1
    80000fce:	8ab2                	mv	s5,a2
  if(va >= MAXVA)
    80000fd0:	57fd                	li	a5,-1
    80000fd2:	83e9                	srli	a5,a5,0x1a
    80000fd4:	4a79                	li	s4,30
    panic("walk");

  for(int level = 2; level > 0; level--) {
    80000fd6:	4b31                	li	s6,12
  if(va >= MAXVA)
    80000fd8:	04b7f263          	bgeu	a5,a1,8000101c <walk+0x66>
    panic("walk");
    80000fdc:	00007517          	auipc	a0,0x7
    80000fe0:	0f450513          	addi	a0,a0,244 # 800080d0 <digits+0x90>
    80000fe4:	fffff097          	auipc	ra,0xfffff
    80000fe8:	55c080e7          	jalr	1372(ra) # 80000540 <panic>
    pte_t *pte = &pagetable[PX(level, va)];
    if(*pte & PTE_V) {
      pagetable = (pagetable_t)PTE2PA(*pte);
    } else {
      if(!alloc || (pagetable = (pde_t*)kalloc()) == 0)
    80000fec:	060a8663          	beqz	s5,80001058 <walk+0xa2>
    80000ff0:	00000097          	auipc	ra,0x0
    80000ff4:	af6080e7          	jalr	-1290(ra) # 80000ae6 <kalloc>
    80000ff8:	84aa                	mv	s1,a0
    80000ffa:	c529                	beqz	a0,80001044 <walk+0x8e>
        return 0;
      memset(pagetable, 0, PGSIZE);
    80000ffc:	6605                	lui	a2,0x1
    80000ffe:	4581                	li	a1,0
    80001000:	00000097          	auipc	ra,0x0
    80001004:	cd2080e7          	jalr	-814(ra) # 80000cd2 <memset>
      *pte = PA2PTE(pagetable) | PTE_V;
    80001008:	00c4d793          	srli	a5,s1,0xc
    8000100c:	07aa                	slli	a5,a5,0xa
    8000100e:	0017e793          	ori	a5,a5,1
    80001012:	00f93023          	sd	a5,0(s2)
  for(int level = 2; level > 0; level--) {
    80001016:	3a5d                	addiw	s4,s4,-9 # ffffffffffffeff7 <end+0xffffffff7ffdc477>
    80001018:	036a0063          	beq	s4,s6,80001038 <walk+0x82>
    pte_t *pte = &pagetable[PX(level, va)];
    8000101c:	0149d933          	srl	s2,s3,s4
    80001020:	1ff97913          	andi	s2,s2,511
    80001024:	090e                	slli	s2,s2,0x3
    80001026:	9926                	add	s2,s2,s1
    if(*pte & PTE_V) {
    80001028:	00093483          	ld	s1,0(s2)
    8000102c:	0014f793          	andi	a5,s1,1
    80001030:	dfd5                	beqz	a5,80000fec <walk+0x36>
      pagetable = (pagetable_t)PTE2PA(*pte);
    80001032:	80a9                	srli	s1,s1,0xa
    80001034:	04b2                	slli	s1,s1,0xc
    80001036:	b7c5                	j	80001016 <walk+0x60>
    }
  }
  return &pagetable[PX(0, va)];
    80001038:	00c9d513          	srli	a0,s3,0xc
    8000103c:	1ff57513          	andi	a0,a0,511
    80001040:	050e                	slli	a0,a0,0x3
    80001042:	9526                	add	a0,a0,s1
}
    80001044:	70e2                	ld	ra,56(sp)
    80001046:	7442                	ld	s0,48(sp)
    80001048:	74a2                	ld	s1,40(sp)
    8000104a:	7902                	ld	s2,32(sp)
    8000104c:	69e2                	ld	s3,24(sp)
    8000104e:	6a42                	ld	s4,16(sp)
    80001050:	6aa2                	ld	s5,8(sp)
    80001052:	6b02                	ld	s6,0(sp)
    80001054:	6121                	addi	sp,sp,64
    80001056:	8082                	ret
        return 0;
    80001058:	4501                	li	a0,0
    8000105a:	b7ed                	j	80001044 <walk+0x8e>

000000008000105c <walkaddr>:
walkaddr(pagetable_t pagetable, uint64 va)
{
  pte_t *pte;
  uint64 pa;

  if(va >= MAXVA)
    8000105c:	57fd                	li	a5,-1
    8000105e:	83e9                	srli	a5,a5,0x1a
    80001060:	00b7f463          	bgeu	a5,a1,80001068 <walkaddr+0xc>
    return 0;
    80001064:	4501                	li	a0,0
    return 0;
  if((*pte & PTE_U) == 0)
    return 0;
  pa = PTE2PA(*pte);
  return pa;
}
    80001066:	8082                	ret
{
    80001068:	1141                	addi	sp,sp,-16
    8000106a:	e406                	sd	ra,8(sp)
    8000106c:	e022                	sd	s0,0(sp)
    8000106e:	0800                	addi	s0,sp,16
  pte = walk(pagetable, va, 0);
    80001070:	4601                	li	a2,0
    80001072:	00000097          	auipc	ra,0x0
    80001076:	f44080e7          	jalr	-188(ra) # 80000fb6 <walk>
  if(pte == 0)
    8000107a:	c105                	beqz	a0,8000109a <walkaddr+0x3e>
  if((*pte & PTE_V) == 0)
    8000107c:	611c                	ld	a5,0(a0)
  if((*pte & PTE_U) == 0)
    8000107e:	0117f693          	andi	a3,a5,17
    80001082:	4745                	li	a4,17
    return 0;
    80001084:	4501                	li	a0,0
  if((*pte & PTE_U) == 0)
    80001086:	00e68663          	beq	a3,a4,80001092 <walkaddr+0x36>
}
    8000108a:	60a2                	ld	ra,8(sp)
    8000108c:	6402                	ld	s0,0(sp)
    8000108e:	0141                	addi	sp,sp,16
    80001090:	8082                	ret
  pa = PTE2PA(*pte);
    80001092:	83a9                	srli	a5,a5,0xa
    80001094:	00c79513          	slli	a0,a5,0xc
  return pa;
    80001098:	bfcd                	j	8000108a <walkaddr+0x2e>
    return 0;
    8000109a:	4501                	li	a0,0
    8000109c:	b7fd                	j	8000108a <walkaddr+0x2e>

000000008000109e <mappages>:
// physical addresses starting at pa. va and size might not
// be page-aligned. Returns 0 on success, -1 if walk() couldn't
// allocate a needed page-table page.
int
mappages(pagetable_t pagetable, uint64 va, uint64 size, uint64 pa, int perm)
{
    8000109e:	715d                	addi	sp,sp,-80
    800010a0:	e486                	sd	ra,72(sp)
    800010a2:	e0a2                	sd	s0,64(sp)
    800010a4:	fc26                	sd	s1,56(sp)
    800010a6:	f84a                	sd	s2,48(sp)
    800010a8:	f44e                	sd	s3,40(sp)
    800010aa:	f052                	sd	s4,32(sp)
    800010ac:	ec56                	sd	s5,24(sp)
    800010ae:	e85a                	sd	s6,16(sp)
    800010b0:	e45e                	sd	s7,8(sp)
    800010b2:	0880                	addi	s0,sp,80
  uint64 a, last;
  pte_t *pte;

  if(size == 0)
    800010b4:	c639                	beqz	a2,80001102 <mappages+0x64>
    800010b6:	8aaa                	mv	s5,a0
    800010b8:	8b3a                	mv	s6,a4
    panic("mappages: size");
  
  a = PGROUNDDOWN(va);
    800010ba:	777d                	lui	a4,0xfffff
    800010bc:	00e5f7b3          	and	a5,a1,a4
  last = PGROUNDDOWN(va + size - 1);
    800010c0:	fff58993          	addi	s3,a1,-1
    800010c4:	99b2                	add	s3,s3,a2
    800010c6:	00e9f9b3          	and	s3,s3,a4
  a = PGROUNDDOWN(va);
    800010ca:	893e                	mv	s2,a5
    800010cc:	40f68a33          	sub	s4,a3,a5
    if(*pte & PTE_V)
      panic("mappages: remap");
    *pte = PA2PTE(pa) | perm | PTE_V;
    if(a == last)
      break;
    a += PGSIZE;
    800010d0:	6b85                	lui	s7,0x1
    800010d2:	012a04b3          	add	s1,s4,s2
    if((pte = walk(pagetable, a, 1)) == 0)
    800010d6:	4605                	li	a2,1
    800010d8:	85ca                	mv	a1,s2
    800010da:	8556                	mv	a0,s5
    800010dc:	00000097          	auipc	ra,0x0
    800010e0:	eda080e7          	jalr	-294(ra) # 80000fb6 <walk>
    800010e4:	cd1d                	beqz	a0,80001122 <mappages+0x84>
    if(*pte & PTE_V)
    800010e6:	611c                	ld	a5,0(a0)
    800010e8:	8b85                	andi	a5,a5,1
    800010ea:	e785                	bnez	a5,80001112 <mappages+0x74>
    *pte = PA2PTE(pa) | perm | PTE_V;
    800010ec:	80b1                	srli	s1,s1,0xc
    800010ee:	04aa                	slli	s1,s1,0xa
    800010f0:	0164e4b3          	or	s1,s1,s6
    800010f4:	0014e493          	ori	s1,s1,1
    800010f8:	e104                	sd	s1,0(a0)
    if(a == last)
    800010fa:	05390063          	beq	s2,s3,8000113a <mappages+0x9c>
    a += PGSIZE;
    800010fe:	995e                	add	s2,s2,s7
    if((pte = walk(pagetable, a, 1)) == 0)
    80001100:	bfc9                	j	800010d2 <mappages+0x34>
    panic("mappages: size");
    80001102:	00007517          	auipc	a0,0x7
    80001106:	fd650513          	addi	a0,a0,-42 # 800080d8 <digits+0x98>
    8000110a:	fffff097          	auipc	ra,0xfffff
    8000110e:	436080e7          	jalr	1078(ra) # 80000540 <panic>
      panic("mappages: remap");
    80001112:	00007517          	auipc	a0,0x7
    80001116:	fd650513          	addi	a0,a0,-42 # 800080e8 <digits+0xa8>
    8000111a:	fffff097          	auipc	ra,0xfffff
    8000111e:	426080e7          	jalr	1062(ra) # 80000540 <panic>
      return -1;
    80001122:	557d                	li	a0,-1
    pa += PGSIZE;
  }
  return 0;
}
    80001124:	60a6                	ld	ra,72(sp)
    80001126:	6406                	ld	s0,64(sp)
    80001128:	74e2                	ld	s1,56(sp)
    8000112a:	7942                	ld	s2,48(sp)
    8000112c:	79a2                	ld	s3,40(sp)
    8000112e:	7a02                	ld	s4,32(sp)
    80001130:	6ae2                	ld	s5,24(sp)
    80001132:	6b42                	ld	s6,16(sp)
    80001134:	6ba2                	ld	s7,8(sp)
    80001136:	6161                	addi	sp,sp,80
    80001138:	8082                	ret
  return 0;
    8000113a:	4501                	li	a0,0
    8000113c:	b7e5                	j	80001124 <mappages+0x86>

000000008000113e <kvmmap>:
{
    8000113e:	1141                	addi	sp,sp,-16
    80001140:	e406                	sd	ra,8(sp)
    80001142:	e022                	sd	s0,0(sp)
    80001144:	0800                	addi	s0,sp,16
    80001146:	87b6                	mv	a5,a3
  if(mappages(kpgtbl, va, sz, pa, perm) != 0)
    80001148:	86b2                	mv	a3,a2
    8000114a:	863e                	mv	a2,a5
    8000114c:	00000097          	auipc	ra,0x0
    80001150:	f52080e7          	jalr	-174(ra) # 8000109e <mappages>
    80001154:	e509                	bnez	a0,8000115e <kvmmap+0x20>
}
    80001156:	60a2                	ld	ra,8(sp)
    80001158:	6402                	ld	s0,0(sp)
    8000115a:	0141                	addi	sp,sp,16
    8000115c:	8082                	ret
    panic("kvmmap");
    8000115e:	00007517          	auipc	a0,0x7
    80001162:	f9a50513          	addi	a0,a0,-102 # 800080f8 <digits+0xb8>
    80001166:	fffff097          	auipc	ra,0xfffff
    8000116a:	3da080e7          	jalr	986(ra) # 80000540 <panic>

000000008000116e <kvmmake>:
{
    8000116e:	1101                	addi	sp,sp,-32
    80001170:	ec06                	sd	ra,24(sp)
    80001172:	e822                	sd	s0,16(sp)
    80001174:	e426                	sd	s1,8(sp)
    80001176:	e04a                	sd	s2,0(sp)
    80001178:	1000                	addi	s0,sp,32
  kpgtbl = (pagetable_t) kalloc();
    8000117a:	00000097          	auipc	ra,0x0
    8000117e:	96c080e7          	jalr	-1684(ra) # 80000ae6 <kalloc>
    80001182:	84aa                	mv	s1,a0
  memset(kpgtbl, 0, PGSIZE);
    80001184:	6605                	lui	a2,0x1
    80001186:	4581                	li	a1,0
    80001188:	00000097          	auipc	ra,0x0
    8000118c:	b4a080e7          	jalr	-1206(ra) # 80000cd2 <memset>
  kvmmap(kpgtbl, UART0, UART0, PGSIZE, PTE_R | PTE_W);
    80001190:	4719                	li	a4,6
    80001192:	6685                	lui	a3,0x1
    80001194:	10000637          	lui	a2,0x10000
    80001198:	100005b7          	lui	a1,0x10000
    8000119c:	8526                	mv	a0,s1
    8000119e:	00000097          	auipc	ra,0x0
    800011a2:	fa0080e7          	jalr	-96(ra) # 8000113e <kvmmap>
  kvmmap(kpgtbl, VIRTIO0, VIRTIO0, PGSIZE, PTE_R | PTE_W);
    800011a6:	4719                	li	a4,6
    800011a8:	6685                	lui	a3,0x1
    800011aa:	10001637          	lui	a2,0x10001
    800011ae:	100015b7          	lui	a1,0x10001
    800011b2:	8526                	mv	a0,s1
    800011b4:	00000097          	auipc	ra,0x0
    800011b8:	f8a080e7          	jalr	-118(ra) # 8000113e <kvmmap>
  kvmmap(kpgtbl, PLIC, PLIC, 0x400000, PTE_R | PTE_W);
    800011bc:	4719                	li	a4,6
    800011be:	004006b7          	lui	a3,0x400
    800011c2:	0c000637          	lui	a2,0xc000
    800011c6:	0c0005b7          	lui	a1,0xc000
    800011ca:	8526                	mv	a0,s1
    800011cc:	00000097          	auipc	ra,0x0
    800011d0:	f72080e7          	jalr	-142(ra) # 8000113e <kvmmap>
  kvmmap(kpgtbl, KERNBASE, KERNBASE, (uint64)etext-KERNBASE, PTE_R | PTE_X);
    800011d4:	00007917          	auipc	s2,0x7
    800011d8:	e2c90913          	addi	s2,s2,-468 # 80008000 <etext>
    800011dc:	4729                	li	a4,10
    800011de:	80007697          	auipc	a3,0x80007
    800011e2:	e2268693          	addi	a3,a3,-478 # 8000 <_entry-0x7fff8000>
    800011e6:	4605                	li	a2,1
    800011e8:	067e                	slli	a2,a2,0x1f
    800011ea:	85b2                	mv	a1,a2
    800011ec:	8526                	mv	a0,s1
    800011ee:	00000097          	auipc	ra,0x0
    800011f2:	f50080e7          	jalr	-176(ra) # 8000113e <kvmmap>
  kvmmap(kpgtbl, (uint64)etext, (uint64)etext, PHYSTOP-(uint64)etext, PTE_R | PTE_W);
    800011f6:	4719                	li	a4,6
    800011f8:	46c5                	li	a3,17
    800011fa:	06ee                	slli	a3,a3,0x1b
    800011fc:	412686b3          	sub	a3,a3,s2
    80001200:	864a                	mv	a2,s2
    80001202:	85ca                	mv	a1,s2
    80001204:	8526                	mv	a0,s1
    80001206:	00000097          	auipc	ra,0x0
    8000120a:	f38080e7          	jalr	-200(ra) # 8000113e <kvmmap>
  kvmmap(kpgtbl, TRAMPOLINE, (uint64)trampoline, PGSIZE, PTE_R | PTE_X);
    8000120e:	4729                	li	a4,10
    80001210:	6685                	lui	a3,0x1
    80001212:	00006617          	auipc	a2,0x6
    80001216:	dee60613          	addi	a2,a2,-530 # 80007000 <_trampoline>
    8000121a:	040005b7          	lui	a1,0x4000
    8000121e:	15fd                	addi	a1,a1,-1 # 3ffffff <_entry-0x7c000001>
    80001220:	05b2                	slli	a1,a1,0xc
    80001222:	8526                	mv	a0,s1
    80001224:	00000097          	auipc	ra,0x0
    80001228:	f1a080e7          	jalr	-230(ra) # 8000113e <kvmmap>
  proc_mapstacks(kpgtbl);
    8000122c:	8526                	mv	a0,s1
    8000122e:	00000097          	auipc	ra,0x0
    80001232:	608080e7          	jalr	1544(ra) # 80001836 <proc_mapstacks>
}
    80001236:	8526                	mv	a0,s1
    80001238:	60e2                	ld	ra,24(sp)
    8000123a:	6442                	ld	s0,16(sp)
    8000123c:	64a2                	ld	s1,8(sp)
    8000123e:	6902                	ld	s2,0(sp)
    80001240:	6105                	addi	sp,sp,32
    80001242:	8082                	ret

0000000080001244 <kvminit>:
{
    80001244:	1141                	addi	sp,sp,-16
    80001246:	e406                	sd	ra,8(sp)
    80001248:	e022                	sd	s0,0(sp)
    8000124a:	0800                	addi	s0,sp,16
  kernel_pagetable = kvmmake();
    8000124c:	00000097          	auipc	ra,0x0
    80001250:	f22080e7          	jalr	-222(ra) # 8000116e <kvmmake>
    80001254:	00007797          	auipc	a5,0x7
    80001258:	68a7be23          	sd	a0,1692(a5) # 800088f0 <kernel_pagetable>
}
    8000125c:	60a2                	ld	ra,8(sp)
    8000125e:	6402                	ld	s0,0(sp)
    80001260:	0141                	addi	sp,sp,16
    80001262:	8082                	ret

0000000080001264 <uvmunmap>:
// Remove npages of mappings starting from va. va must be
// page-aligned. The mappings must exist.
// Optionally free the physical memory.
void
uvmunmap(pagetable_t pagetable, uint64 va, uint64 npages, int do_free)
{
    80001264:	715d                	addi	sp,sp,-80
    80001266:	e486                	sd	ra,72(sp)
    80001268:	e0a2                	sd	s0,64(sp)
    8000126a:	fc26                	sd	s1,56(sp)
    8000126c:	f84a                	sd	s2,48(sp)
    8000126e:	f44e                	sd	s3,40(sp)
    80001270:	f052                	sd	s4,32(sp)
    80001272:	ec56                	sd	s5,24(sp)
    80001274:	e85a                	sd	s6,16(sp)
    80001276:	e45e                	sd	s7,8(sp)
    80001278:	0880                	addi	s0,sp,80
  uint64 a;
  pte_t *pte;

  if((va % PGSIZE) != 0)
    8000127a:	03459793          	slli	a5,a1,0x34
    8000127e:	e795                	bnez	a5,800012aa <uvmunmap+0x46>
    80001280:	8a2a                	mv	s4,a0
    80001282:	892e                	mv	s2,a1
    80001284:	8ab6                	mv	s5,a3
    panic("uvmunmap: not aligned");

  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    80001286:	0632                	slli	a2,a2,0xc
    80001288:	00b609b3          	add	s3,a2,a1
    if((pte = walk(pagetable, a, 0)) == 0)
      panic("uvmunmap: walk");
    if((*pte & PTE_V) == 0)
      panic("uvmunmap: not mapped");
    if(PTE_FLAGS(*pte) == PTE_V)
    8000128c:	4b85                	li	s7,1
  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    8000128e:	6b05                	lui	s6,0x1
    80001290:	0735e263          	bltu	a1,s3,800012f4 <uvmunmap+0x90>
      uint64 pa = PTE2PA(*pte);
      kfree((void*)pa);
    }
    *pte = 0;
  }
}
    80001294:	60a6                	ld	ra,72(sp)
    80001296:	6406                	ld	s0,64(sp)
    80001298:	74e2                	ld	s1,56(sp)
    8000129a:	7942                	ld	s2,48(sp)
    8000129c:	79a2                	ld	s3,40(sp)
    8000129e:	7a02                	ld	s4,32(sp)
    800012a0:	6ae2                	ld	s5,24(sp)
    800012a2:	6b42                	ld	s6,16(sp)
    800012a4:	6ba2                	ld	s7,8(sp)
    800012a6:	6161                	addi	sp,sp,80
    800012a8:	8082                	ret
    panic("uvmunmap: not aligned");
    800012aa:	00007517          	auipc	a0,0x7
    800012ae:	e5650513          	addi	a0,a0,-426 # 80008100 <digits+0xc0>
    800012b2:	fffff097          	auipc	ra,0xfffff
    800012b6:	28e080e7          	jalr	654(ra) # 80000540 <panic>
      panic("uvmunmap: walk");
    800012ba:	00007517          	auipc	a0,0x7
    800012be:	e5e50513          	addi	a0,a0,-418 # 80008118 <digits+0xd8>
    800012c2:	fffff097          	auipc	ra,0xfffff
    800012c6:	27e080e7          	jalr	638(ra) # 80000540 <panic>
      panic("uvmunmap: not mapped");
    800012ca:	00007517          	auipc	a0,0x7
    800012ce:	e5e50513          	addi	a0,a0,-418 # 80008128 <digits+0xe8>
    800012d2:	fffff097          	auipc	ra,0xfffff
    800012d6:	26e080e7          	jalr	622(ra) # 80000540 <panic>
      panic("uvmunmap: not a leaf");
    800012da:	00007517          	auipc	a0,0x7
    800012de:	e6650513          	addi	a0,a0,-410 # 80008140 <digits+0x100>
    800012e2:	fffff097          	auipc	ra,0xfffff
    800012e6:	25e080e7          	jalr	606(ra) # 80000540 <panic>
    *pte = 0;
    800012ea:	0004b023          	sd	zero,0(s1)
  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    800012ee:	995a                	add	s2,s2,s6
    800012f0:	fb3972e3          	bgeu	s2,s3,80001294 <uvmunmap+0x30>
    if((pte = walk(pagetable, a, 0)) == 0)
    800012f4:	4601                	li	a2,0
    800012f6:	85ca                	mv	a1,s2
    800012f8:	8552                	mv	a0,s4
    800012fa:	00000097          	auipc	ra,0x0
    800012fe:	cbc080e7          	jalr	-836(ra) # 80000fb6 <walk>
    80001302:	84aa                	mv	s1,a0
    80001304:	d95d                	beqz	a0,800012ba <uvmunmap+0x56>
    if((*pte & PTE_V) == 0)
    80001306:	6108                	ld	a0,0(a0)
    80001308:	00157793          	andi	a5,a0,1
    8000130c:	dfdd                	beqz	a5,800012ca <uvmunmap+0x66>
    if(PTE_FLAGS(*pte) == PTE_V)
    8000130e:	3ff57793          	andi	a5,a0,1023
    80001312:	fd7784e3          	beq	a5,s7,800012da <uvmunmap+0x76>
    if(do_free){
    80001316:	fc0a8ae3          	beqz	s5,800012ea <uvmunmap+0x86>
      uint64 pa = PTE2PA(*pte);
    8000131a:	8129                	srli	a0,a0,0xa
      kfree((void*)pa);
    8000131c:	0532                	slli	a0,a0,0xc
    8000131e:	fffff097          	auipc	ra,0xfffff
    80001322:	6ca080e7          	jalr	1738(ra) # 800009e8 <kfree>
    80001326:	b7d1                	j	800012ea <uvmunmap+0x86>

0000000080001328 <uvmcreate>:

// create an empty user page table.
// returns 0 if out of memory.
pagetable_t
uvmcreate()
{
    80001328:	1101                	addi	sp,sp,-32
    8000132a:	ec06                	sd	ra,24(sp)
    8000132c:	e822                	sd	s0,16(sp)
    8000132e:	e426                	sd	s1,8(sp)
    80001330:	1000                	addi	s0,sp,32
  pagetable_t pagetable;
  pagetable = (pagetable_t) kalloc();
    80001332:	fffff097          	auipc	ra,0xfffff
    80001336:	7b4080e7          	jalr	1972(ra) # 80000ae6 <kalloc>
    8000133a:	84aa                	mv	s1,a0
  if(pagetable == 0)
    8000133c:	c519                	beqz	a0,8000134a <uvmcreate+0x22>
    return 0;
  memset(pagetable, 0, PGSIZE);
    8000133e:	6605                	lui	a2,0x1
    80001340:	4581                	li	a1,0
    80001342:	00000097          	auipc	ra,0x0
    80001346:	990080e7          	jalr	-1648(ra) # 80000cd2 <memset>
  return pagetable;
}
    8000134a:	8526                	mv	a0,s1
    8000134c:	60e2                	ld	ra,24(sp)
    8000134e:	6442                	ld	s0,16(sp)
    80001350:	64a2                	ld	s1,8(sp)
    80001352:	6105                	addi	sp,sp,32
    80001354:	8082                	ret

0000000080001356 <uvmfirst>:
// Load the user initcode into address 0 of pagetable,
// for the very first process.
// sz must be less than a page.
void
uvmfirst(pagetable_t pagetable, uchar *src, uint sz)
{
    80001356:	7179                	addi	sp,sp,-48
    80001358:	f406                	sd	ra,40(sp)
    8000135a:	f022                	sd	s0,32(sp)
    8000135c:	ec26                	sd	s1,24(sp)
    8000135e:	e84a                	sd	s2,16(sp)
    80001360:	e44e                	sd	s3,8(sp)
    80001362:	e052                	sd	s4,0(sp)
    80001364:	1800                	addi	s0,sp,48
  char *mem;

  if(sz >= PGSIZE)
    80001366:	6785                	lui	a5,0x1
    80001368:	04f67863          	bgeu	a2,a5,800013b8 <uvmfirst+0x62>
    8000136c:	8a2a                	mv	s4,a0
    8000136e:	89ae                	mv	s3,a1
    80001370:	84b2                	mv	s1,a2
    panic("uvmfirst: more than a page");
  mem = kalloc();
    80001372:	fffff097          	auipc	ra,0xfffff
    80001376:	774080e7          	jalr	1908(ra) # 80000ae6 <kalloc>
    8000137a:	892a                	mv	s2,a0
  memset(mem, 0, PGSIZE);
    8000137c:	6605                	lui	a2,0x1
    8000137e:	4581                	li	a1,0
    80001380:	00000097          	auipc	ra,0x0
    80001384:	952080e7          	jalr	-1710(ra) # 80000cd2 <memset>
  mappages(pagetable, 0, PGSIZE, (uint64)mem, PTE_W|PTE_R|PTE_X|PTE_U);
    80001388:	4779                	li	a4,30
    8000138a:	86ca                	mv	a3,s2
    8000138c:	6605                	lui	a2,0x1
    8000138e:	4581                	li	a1,0
    80001390:	8552                	mv	a0,s4
    80001392:	00000097          	auipc	ra,0x0
    80001396:	d0c080e7          	jalr	-756(ra) # 8000109e <mappages>
  memmove(mem, src, sz);
    8000139a:	8626                	mv	a2,s1
    8000139c:	85ce                	mv	a1,s3
    8000139e:	854a                	mv	a0,s2
    800013a0:	00000097          	auipc	ra,0x0
    800013a4:	98e080e7          	jalr	-1650(ra) # 80000d2e <memmove>
}
    800013a8:	70a2                	ld	ra,40(sp)
    800013aa:	7402                	ld	s0,32(sp)
    800013ac:	64e2                	ld	s1,24(sp)
    800013ae:	6942                	ld	s2,16(sp)
    800013b0:	69a2                	ld	s3,8(sp)
    800013b2:	6a02                	ld	s4,0(sp)
    800013b4:	6145                	addi	sp,sp,48
    800013b6:	8082                	ret
    panic("uvmfirst: more than a page");
    800013b8:	00007517          	auipc	a0,0x7
    800013bc:	da050513          	addi	a0,a0,-608 # 80008158 <digits+0x118>
    800013c0:	fffff097          	auipc	ra,0xfffff
    800013c4:	180080e7          	jalr	384(ra) # 80000540 <panic>

00000000800013c8 <uvmdealloc>:
// newsz.  oldsz and newsz need not be page-aligned, nor does newsz
// need to be less than oldsz.  oldsz can be larger than the actual
// process size.  Returns the new process size.
uint64
uvmdealloc(pagetable_t pagetable, uint64 oldsz, uint64 newsz)
{
    800013c8:	1101                	addi	sp,sp,-32
    800013ca:	ec06                	sd	ra,24(sp)
    800013cc:	e822                	sd	s0,16(sp)
    800013ce:	e426                	sd	s1,8(sp)
    800013d0:	1000                	addi	s0,sp,32
  if(newsz >= oldsz)
    return oldsz;
    800013d2:	84ae                	mv	s1,a1
  if(newsz >= oldsz)
    800013d4:	00b67d63          	bgeu	a2,a1,800013ee <uvmdealloc+0x26>
    800013d8:	84b2                	mv	s1,a2

  if(PGROUNDUP(newsz) < PGROUNDUP(oldsz)){
    800013da:	6785                	lui	a5,0x1
    800013dc:	17fd                	addi	a5,a5,-1 # fff <_entry-0x7ffff001>
    800013de:	00f60733          	add	a4,a2,a5
    800013e2:	76fd                	lui	a3,0xfffff
    800013e4:	8f75                	and	a4,a4,a3
    800013e6:	97ae                	add	a5,a5,a1
    800013e8:	8ff5                	and	a5,a5,a3
    800013ea:	00f76863          	bltu	a4,a5,800013fa <uvmdealloc+0x32>
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
  }

  return newsz;
}
    800013ee:	8526                	mv	a0,s1
    800013f0:	60e2                	ld	ra,24(sp)
    800013f2:	6442                	ld	s0,16(sp)
    800013f4:	64a2                	ld	s1,8(sp)
    800013f6:	6105                	addi	sp,sp,32
    800013f8:	8082                	ret
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    800013fa:	8f99                	sub	a5,a5,a4
    800013fc:	83b1                	srli	a5,a5,0xc
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
    800013fe:	4685                	li	a3,1
    80001400:	0007861b          	sext.w	a2,a5
    80001404:	85ba                	mv	a1,a4
    80001406:	00000097          	auipc	ra,0x0
    8000140a:	e5e080e7          	jalr	-418(ra) # 80001264 <uvmunmap>
    8000140e:	b7c5                	j	800013ee <uvmdealloc+0x26>

0000000080001410 <uvmalloc>:
  if(newsz < oldsz)
    80001410:	0ab66563          	bltu	a2,a1,800014ba <uvmalloc+0xaa>
{
    80001414:	7139                	addi	sp,sp,-64
    80001416:	fc06                	sd	ra,56(sp)
    80001418:	f822                	sd	s0,48(sp)
    8000141a:	f426                	sd	s1,40(sp)
    8000141c:	f04a                	sd	s2,32(sp)
    8000141e:	ec4e                	sd	s3,24(sp)
    80001420:	e852                	sd	s4,16(sp)
    80001422:	e456                	sd	s5,8(sp)
    80001424:	e05a                	sd	s6,0(sp)
    80001426:	0080                	addi	s0,sp,64
    80001428:	8aaa                	mv	s5,a0
    8000142a:	8a32                	mv	s4,a2
  oldsz = PGROUNDUP(oldsz);
    8000142c:	6785                	lui	a5,0x1
    8000142e:	17fd                	addi	a5,a5,-1 # fff <_entry-0x7ffff001>
    80001430:	95be                	add	a1,a1,a5
    80001432:	77fd                	lui	a5,0xfffff
    80001434:	00f5f9b3          	and	s3,a1,a5
  for(a = oldsz; a < newsz; a += PGSIZE){
    80001438:	08c9f363          	bgeu	s3,a2,800014be <uvmalloc+0xae>
    8000143c:	894e                	mv	s2,s3
    if(mappages(pagetable, a, PGSIZE, (uint64)mem, PTE_R|PTE_U|xperm) != 0){
    8000143e:	0126eb13          	ori	s6,a3,18
    mem = kalloc();
    80001442:	fffff097          	auipc	ra,0xfffff
    80001446:	6a4080e7          	jalr	1700(ra) # 80000ae6 <kalloc>
    8000144a:	84aa                	mv	s1,a0
    if(mem == 0){
    8000144c:	c51d                	beqz	a0,8000147a <uvmalloc+0x6a>
    memset(mem, 0, PGSIZE);
    8000144e:	6605                	lui	a2,0x1
    80001450:	4581                	li	a1,0
    80001452:	00000097          	auipc	ra,0x0
    80001456:	880080e7          	jalr	-1920(ra) # 80000cd2 <memset>
    if(mappages(pagetable, a, PGSIZE, (uint64)mem, PTE_R|PTE_U|xperm) != 0){
    8000145a:	875a                	mv	a4,s6
    8000145c:	86a6                	mv	a3,s1
    8000145e:	6605                	lui	a2,0x1
    80001460:	85ca                	mv	a1,s2
    80001462:	8556                	mv	a0,s5
    80001464:	00000097          	auipc	ra,0x0
    80001468:	c3a080e7          	jalr	-966(ra) # 8000109e <mappages>
    8000146c:	e90d                	bnez	a0,8000149e <uvmalloc+0x8e>
  for(a = oldsz; a < newsz; a += PGSIZE){
    8000146e:	6785                	lui	a5,0x1
    80001470:	993e                	add	s2,s2,a5
    80001472:	fd4968e3          	bltu	s2,s4,80001442 <uvmalloc+0x32>
  return newsz;
    80001476:	8552                	mv	a0,s4
    80001478:	a809                	j	8000148a <uvmalloc+0x7a>
      uvmdealloc(pagetable, a, oldsz);
    8000147a:	864e                	mv	a2,s3
    8000147c:	85ca                	mv	a1,s2
    8000147e:	8556                	mv	a0,s5
    80001480:	00000097          	auipc	ra,0x0
    80001484:	f48080e7          	jalr	-184(ra) # 800013c8 <uvmdealloc>
      return 0;
    80001488:	4501                	li	a0,0
}
    8000148a:	70e2                	ld	ra,56(sp)
    8000148c:	7442                	ld	s0,48(sp)
    8000148e:	74a2                	ld	s1,40(sp)
    80001490:	7902                	ld	s2,32(sp)
    80001492:	69e2                	ld	s3,24(sp)
    80001494:	6a42                	ld	s4,16(sp)
    80001496:	6aa2                	ld	s5,8(sp)
    80001498:	6b02                	ld	s6,0(sp)
    8000149a:	6121                	addi	sp,sp,64
    8000149c:	8082                	ret
      kfree(mem);
    8000149e:	8526                	mv	a0,s1
    800014a0:	fffff097          	auipc	ra,0xfffff
    800014a4:	548080e7          	jalr	1352(ra) # 800009e8 <kfree>
      uvmdealloc(pagetable, a, oldsz);
    800014a8:	864e                	mv	a2,s3
    800014aa:	85ca                	mv	a1,s2
    800014ac:	8556                	mv	a0,s5
    800014ae:	00000097          	auipc	ra,0x0
    800014b2:	f1a080e7          	jalr	-230(ra) # 800013c8 <uvmdealloc>
      return 0;
    800014b6:	4501                	li	a0,0
    800014b8:	bfc9                	j	8000148a <uvmalloc+0x7a>
    return oldsz;
    800014ba:	852e                	mv	a0,a1
}
    800014bc:	8082                	ret
  return newsz;
    800014be:	8532                	mv	a0,a2
    800014c0:	b7e9                	j	8000148a <uvmalloc+0x7a>

00000000800014c2 <freewalk>:

// Recursively free page-table pages.
// All leaf mappings must already have been removed.
void
freewalk(pagetable_t pagetable)
{
    800014c2:	7179                	addi	sp,sp,-48
    800014c4:	f406                	sd	ra,40(sp)
    800014c6:	f022                	sd	s0,32(sp)
    800014c8:	ec26                	sd	s1,24(sp)
    800014ca:	e84a                	sd	s2,16(sp)
    800014cc:	e44e                	sd	s3,8(sp)
    800014ce:	e052                	sd	s4,0(sp)
    800014d0:	1800                	addi	s0,sp,48
    800014d2:	8a2a                	mv	s4,a0
  // there are 2^9 = 512 PTEs in a page table.
  for(int i = 0; i < 512; i++){
    800014d4:	84aa                	mv	s1,a0
    800014d6:	6905                	lui	s2,0x1
    800014d8:	992a                	add	s2,s2,a0
    pte_t pte = pagetable[i];
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    800014da:	4985                	li	s3,1
    800014dc:	a829                	j	800014f6 <freewalk+0x34>
      // this PTE points to a lower-level page table.
      uint64 child = PTE2PA(pte);
    800014de:	83a9                	srli	a5,a5,0xa
      freewalk((pagetable_t)child);
    800014e0:	00c79513          	slli	a0,a5,0xc
    800014e4:	00000097          	auipc	ra,0x0
    800014e8:	fde080e7          	jalr	-34(ra) # 800014c2 <freewalk>
      pagetable[i] = 0;
    800014ec:	0004b023          	sd	zero,0(s1)
  for(int i = 0; i < 512; i++){
    800014f0:	04a1                	addi	s1,s1,8
    800014f2:	03248163          	beq	s1,s2,80001514 <freewalk+0x52>
    pte_t pte = pagetable[i];
    800014f6:	609c                	ld	a5,0(s1)
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    800014f8:	00f7f713          	andi	a4,a5,15
    800014fc:	ff3701e3          	beq	a4,s3,800014de <freewalk+0x1c>
    } else if(pte & PTE_V){
    80001500:	8b85                	andi	a5,a5,1
    80001502:	d7fd                	beqz	a5,800014f0 <freewalk+0x2e>
      panic("freewalk: leaf");
    80001504:	00007517          	auipc	a0,0x7
    80001508:	c7450513          	addi	a0,a0,-908 # 80008178 <digits+0x138>
    8000150c:	fffff097          	auipc	ra,0xfffff
    80001510:	034080e7          	jalr	52(ra) # 80000540 <panic>
    }
  }
  kfree((void*)pagetable);
    80001514:	8552                	mv	a0,s4
    80001516:	fffff097          	auipc	ra,0xfffff
    8000151a:	4d2080e7          	jalr	1234(ra) # 800009e8 <kfree>
}
    8000151e:	70a2                	ld	ra,40(sp)
    80001520:	7402                	ld	s0,32(sp)
    80001522:	64e2                	ld	s1,24(sp)
    80001524:	6942                	ld	s2,16(sp)
    80001526:	69a2                	ld	s3,8(sp)
    80001528:	6a02                	ld	s4,0(sp)
    8000152a:	6145                	addi	sp,sp,48
    8000152c:	8082                	ret

000000008000152e <uvmfree>:

// Free user memory pages,
// then free page-table pages.
void
uvmfree(pagetable_t pagetable, uint64 sz)
{
    8000152e:	1101                	addi	sp,sp,-32
    80001530:	ec06                	sd	ra,24(sp)
    80001532:	e822                	sd	s0,16(sp)
    80001534:	e426                	sd	s1,8(sp)
    80001536:	1000                	addi	s0,sp,32
    80001538:	84aa                	mv	s1,a0
  if(sz > 0)
    8000153a:	e999                	bnez	a1,80001550 <uvmfree+0x22>
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
  freewalk(pagetable);
    8000153c:	8526                	mv	a0,s1
    8000153e:	00000097          	auipc	ra,0x0
    80001542:	f84080e7          	jalr	-124(ra) # 800014c2 <freewalk>
}
    80001546:	60e2                	ld	ra,24(sp)
    80001548:	6442                	ld	s0,16(sp)
    8000154a:	64a2                	ld	s1,8(sp)
    8000154c:	6105                	addi	sp,sp,32
    8000154e:	8082                	ret
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
    80001550:	6785                	lui	a5,0x1
    80001552:	17fd                	addi	a5,a5,-1 # fff <_entry-0x7ffff001>
    80001554:	95be                	add	a1,a1,a5
    80001556:	4685                	li	a3,1
    80001558:	00c5d613          	srli	a2,a1,0xc
    8000155c:	4581                	li	a1,0
    8000155e:	00000097          	auipc	ra,0x0
    80001562:	d06080e7          	jalr	-762(ra) # 80001264 <uvmunmap>
    80001566:	bfd9                	j	8000153c <uvmfree+0xe>

0000000080001568 <uvmcopy>:
  pte_t *pte;
  uint64 pa, i;
  uint flags;
  char *mem;

  for(i = 0; i < sz; i += PGSIZE){
    80001568:	c679                	beqz	a2,80001636 <uvmcopy+0xce>
{
    8000156a:	715d                	addi	sp,sp,-80
    8000156c:	e486                	sd	ra,72(sp)
    8000156e:	e0a2                	sd	s0,64(sp)
    80001570:	fc26                	sd	s1,56(sp)
    80001572:	f84a                	sd	s2,48(sp)
    80001574:	f44e                	sd	s3,40(sp)
    80001576:	f052                	sd	s4,32(sp)
    80001578:	ec56                	sd	s5,24(sp)
    8000157a:	e85a                	sd	s6,16(sp)
    8000157c:	e45e                	sd	s7,8(sp)
    8000157e:	0880                	addi	s0,sp,80
    80001580:	8b2a                	mv	s6,a0
    80001582:	8aae                	mv	s5,a1
    80001584:	8a32                	mv	s4,a2
  for(i = 0; i < sz; i += PGSIZE){
    80001586:	4981                	li	s3,0
    if((pte = walk(old, i, 0)) == 0)
    80001588:	4601                	li	a2,0
    8000158a:	85ce                	mv	a1,s3
    8000158c:	855a                	mv	a0,s6
    8000158e:	00000097          	auipc	ra,0x0
    80001592:	a28080e7          	jalr	-1496(ra) # 80000fb6 <walk>
    80001596:	c531                	beqz	a0,800015e2 <uvmcopy+0x7a>
      panic("uvmcopy: pte should exist");
    if((*pte & PTE_V) == 0)
    80001598:	6118                	ld	a4,0(a0)
    8000159a:	00177793          	andi	a5,a4,1
    8000159e:	cbb1                	beqz	a5,800015f2 <uvmcopy+0x8a>
      panic("uvmcopy: page not present");
    pa = PTE2PA(*pte);
    800015a0:	00a75593          	srli	a1,a4,0xa
    800015a4:	00c59b93          	slli	s7,a1,0xc
    flags = PTE_FLAGS(*pte);
    800015a8:	3ff77493          	andi	s1,a4,1023
    if((mem = kalloc()) == 0)
    800015ac:	fffff097          	auipc	ra,0xfffff
    800015b0:	53a080e7          	jalr	1338(ra) # 80000ae6 <kalloc>
    800015b4:	892a                	mv	s2,a0
    800015b6:	c939                	beqz	a0,8000160c <uvmcopy+0xa4>
      goto err;
    memmove(mem, (char*)pa, PGSIZE);
    800015b8:	6605                	lui	a2,0x1
    800015ba:	85de                	mv	a1,s7
    800015bc:	fffff097          	auipc	ra,0xfffff
    800015c0:	772080e7          	jalr	1906(ra) # 80000d2e <memmove>
    if(mappages(new, i, PGSIZE, (uint64)mem, flags) != 0){
    800015c4:	8726                	mv	a4,s1
    800015c6:	86ca                	mv	a3,s2
    800015c8:	6605                	lui	a2,0x1
    800015ca:	85ce                	mv	a1,s3
    800015cc:	8556                	mv	a0,s5
    800015ce:	00000097          	auipc	ra,0x0
    800015d2:	ad0080e7          	jalr	-1328(ra) # 8000109e <mappages>
    800015d6:	e515                	bnez	a0,80001602 <uvmcopy+0x9a>
  for(i = 0; i < sz; i += PGSIZE){
    800015d8:	6785                	lui	a5,0x1
    800015da:	99be                	add	s3,s3,a5
    800015dc:	fb49e6e3          	bltu	s3,s4,80001588 <uvmcopy+0x20>
    800015e0:	a081                	j	80001620 <uvmcopy+0xb8>
      panic("uvmcopy: pte should exist");
    800015e2:	00007517          	auipc	a0,0x7
    800015e6:	ba650513          	addi	a0,a0,-1114 # 80008188 <digits+0x148>
    800015ea:	fffff097          	auipc	ra,0xfffff
    800015ee:	f56080e7          	jalr	-170(ra) # 80000540 <panic>
      panic("uvmcopy: page not present");
    800015f2:	00007517          	auipc	a0,0x7
    800015f6:	bb650513          	addi	a0,a0,-1098 # 800081a8 <digits+0x168>
    800015fa:	fffff097          	auipc	ra,0xfffff
    800015fe:	f46080e7          	jalr	-186(ra) # 80000540 <panic>
      kfree(mem);
    80001602:	854a                	mv	a0,s2
    80001604:	fffff097          	auipc	ra,0xfffff
    80001608:	3e4080e7          	jalr	996(ra) # 800009e8 <kfree>
    }
  }
  return 0;

 err:
  uvmunmap(new, 0, i / PGSIZE, 1);
    8000160c:	4685                	li	a3,1
    8000160e:	00c9d613          	srli	a2,s3,0xc
    80001612:	4581                	li	a1,0
    80001614:	8556                	mv	a0,s5
    80001616:	00000097          	auipc	ra,0x0
    8000161a:	c4e080e7          	jalr	-946(ra) # 80001264 <uvmunmap>
  return -1;
    8000161e:	557d                	li	a0,-1
}
    80001620:	60a6                	ld	ra,72(sp)
    80001622:	6406                	ld	s0,64(sp)
    80001624:	74e2                	ld	s1,56(sp)
    80001626:	7942                	ld	s2,48(sp)
    80001628:	79a2                	ld	s3,40(sp)
    8000162a:	7a02                	ld	s4,32(sp)
    8000162c:	6ae2                	ld	s5,24(sp)
    8000162e:	6b42                	ld	s6,16(sp)
    80001630:	6ba2                	ld	s7,8(sp)
    80001632:	6161                	addi	sp,sp,80
    80001634:	8082                	ret
  return 0;
    80001636:	4501                	li	a0,0
}
    80001638:	8082                	ret

000000008000163a <uvmclear>:

// mark a PTE invalid for user access.
// used by exec for the user stack guard page.
void
uvmclear(pagetable_t pagetable, uint64 va)
{
    8000163a:	1141                	addi	sp,sp,-16
    8000163c:	e406                	sd	ra,8(sp)
    8000163e:	e022                	sd	s0,0(sp)
    80001640:	0800                	addi	s0,sp,16
  pte_t *pte;
  
  pte = walk(pagetable, va, 0);
    80001642:	4601                	li	a2,0
    80001644:	00000097          	auipc	ra,0x0
    80001648:	972080e7          	jalr	-1678(ra) # 80000fb6 <walk>
  if(pte == 0)
    8000164c:	c901                	beqz	a0,8000165c <uvmclear+0x22>
    panic("uvmclear");
  *pte &= ~PTE_U;
    8000164e:	611c                	ld	a5,0(a0)
    80001650:	9bbd                	andi	a5,a5,-17
    80001652:	e11c                	sd	a5,0(a0)
}
    80001654:	60a2                	ld	ra,8(sp)
    80001656:	6402                	ld	s0,0(sp)
    80001658:	0141                	addi	sp,sp,16
    8000165a:	8082                	ret
    panic("uvmclear");
    8000165c:	00007517          	auipc	a0,0x7
    80001660:	b6c50513          	addi	a0,a0,-1172 # 800081c8 <digits+0x188>
    80001664:	fffff097          	auipc	ra,0xfffff
    80001668:	edc080e7          	jalr	-292(ra) # 80000540 <panic>

000000008000166c <copyout>:
int
copyout(pagetable_t pagetable, uint64 dstva, char *src, uint64 len)
{
  uint64 n, va0, pa0;

  while(len > 0){
    8000166c:	c6bd                	beqz	a3,800016da <copyout+0x6e>
{
    8000166e:	715d                	addi	sp,sp,-80
    80001670:	e486                	sd	ra,72(sp)
    80001672:	e0a2                	sd	s0,64(sp)
    80001674:	fc26                	sd	s1,56(sp)
    80001676:	f84a                	sd	s2,48(sp)
    80001678:	f44e                	sd	s3,40(sp)
    8000167a:	f052                	sd	s4,32(sp)
    8000167c:	ec56                	sd	s5,24(sp)
    8000167e:	e85a                	sd	s6,16(sp)
    80001680:	e45e                	sd	s7,8(sp)
    80001682:	e062                	sd	s8,0(sp)
    80001684:	0880                	addi	s0,sp,80
    80001686:	8b2a                	mv	s6,a0
    80001688:	8c2e                	mv	s8,a1
    8000168a:	8a32                	mv	s4,a2
    8000168c:	89b6                	mv	s3,a3
    va0 = PGROUNDDOWN(dstva);
    8000168e:	7bfd                	lui	s7,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (dstva - va0);
    80001690:	6a85                	lui	s5,0x1
    80001692:	a015                	j	800016b6 <copyout+0x4a>
    if(n > len)
      n = len;
    memmove((void *)(pa0 + (dstva - va0)), src, n);
    80001694:	9562                	add	a0,a0,s8
    80001696:	0004861b          	sext.w	a2,s1
    8000169a:	85d2                	mv	a1,s4
    8000169c:	41250533          	sub	a0,a0,s2
    800016a0:	fffff097          	auipc	ra,0xfffff
    800016a4:	68e080e7          	jalr	1678(ra) # 80000d2e <memmove>

    len -= n;
    800016a8:	409989b3          	sub	s3,s3,s1
    src += n;
    800016ac:	9a26                	add	s4,s4,s1
    dstva = va0 + PGSIZE;
    800016ae:	01590c33          	add	s8,s2,s5
  while(len > 0){
    800016b2:	02098263          	beqz	s3,800016d6 <copyout+0x6a>
    va0 = PGROUNDDOWN(dstva);
    800016b6:	017c7933          	and	s2,s8,s7
    pa0 = walkaddr(pagetable, va0);
    800016ba:	85ca                	mv	a1,s2
    800016bc:	855a                	mv	a0,s6
    800016be:	00000097          	auipc	ra,0x0
    800016c2:	99e080e7          	jalr	-1634(ra) # 8000105c <walkaddr>
    if(pa0 == 0)
    800016c6:	cd01                	beqz	a0,800016de <copyout+0x72>
    n = PGSIZE - (dstva - va0);
    800016c8:	418904b3          	sub	s1,s2,s8
    800016cc:	94d6                	add	s1,s1,s5
    800016ce:	fc99f3e3          	bgeu	s3,s1,80001694 <copyout+0x28>
    800016d2:	84ce                	mv	s1,s3
    800016d4:	b7c1                	j	80001694 <copyout+0x28>
  }
  return 0;
    800016d6:	4501                	li	a0,0
    800016d8:	a021                	j	800016e0 <copyout+0x74>
    800016da:	4501                	li	a0,0
}
    800016dc:	8082                	ret
      return -1;
    800016de:	557d                	li	a0,-1
}
    800016e0:	60a6                	ld	ra,72(sp)
    800016e2:	6406                	ld	s0,64(sp)
    800016e4:	74e2                	ld	s1,56(sp)
    800016e6:	7942                	ld	s2,48(sp)
    800016e8:	79a2                	ld	s3,40(sp)
    800016ea:	7a02                	ld	s4,32(sp)
    800016ec:	6ae2                	ld	s5,24(sp)
    800016ee:	6b42                	ld	s6,16(sp)
    800016f0:	6ba2                	ld	s7,8(sp)
    800016f2:	6c02                	ld	s8,0(sp)
    800016f4:	6161                	addi	sp,sp,80
    800016f6:	8082                	ret

00000000800016f8 <copyin>:
int
copyin(pagetable_t pagetable, char *dst, uint64 srcva, uint64 len)
{
  uint64 n, va0, pa0;

  while(len > 0){
    800016f8:	caa5                	beqz	a3,80001768 <copyin+0x70>
{
    800016fa:	715d                	addi	sp,sp,-80
    800016fc:	e486                	sd	ra,72(sp)
    800016fe:	e0a2                	sd	s0,64(sp)
    80001700:	fc26                	sd	s1,56(sp)
    80001702:	f84a                	sd	s2,48(sp)
    80001704:	f44e                	sd	s3,40(sp)
    80001706:	f052                	sd	s4,32(sp)
    80001708:	ec56                	sd	s5,24(sp)
    8000170a:	e85a                	sd	s6,16(sp)
    8000170c:	e45e                	sd	s7,8(sp)
    8000170e:	e062                	sd	s8,0(sp)
    80001710:	0880                	addi	s0,sp,80
    80001712:	8b2a                	mv	s6,a0
    80001714:	8a2e                	mv	s4,a1
    80001716:	8c32                	mv	s8,a2
    80001718:	89b6                	mv	s3,a3
    va0 = PGROUNDDOWN(srcva);
    8000171a:	7bfd                	lui	s7,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    8000171c:	6a85                	lui	s5,0x1
    8000171e:	a01d                	j	80001744 <copyin+0x4c>
    if(n > len)
      n = len;
    memmove(dst, (void *)(pa0 + (srcva - va0)), n);
    80001720:	018505b3          	add	a1,a0,s8
    80001724:	0004861b          	sext.w	a2,s1
    80001728:	412585b3          	sub	a1,a1,s2
    8000172c:	8552                	mv	a0,s4
    8000172e:	fffff097          	auipc	ra,0xfffff
    80001732:	600080e7          	jalr	1536(ra) # 80000d2e <memmove>

    len -= n;
    80001736:	409989b3          	sub	s3,s3,s1
    dst += n;
    8000173a:	9a26                	add	s4,s4,s1
    srcva = va0 + PGSIZE;
    8000173c:	01590c33          	add	s8,s2,s5
  while(len > 0){
    80001740:	02098263          	beqz	s3,80001764 <copyin+0x6c>
    va0 = PGROUNDDOWN(srcva);
    80001744:	017c7933          	and	s2,s8,s7
    pa0 = walkaddr(pagetable, va0);
    80001748:	85ca                	mv	a1,s2
    8000174a:	855a                	mv	a0,s6
    8000174c:	00000097          	auipc	ra,0x0
    80001750:	910080e7          	jalr	-1776(ra) # 8000105c <walkaddr>
    if(pa0 == 0)
    80001754:	cd01                	beqz	a0,8000176c <copyin+0x74>
    n = PGSIZE - (srcva - va0);
    80001756:	418904b3          	sub	s1,s2,s8
    8000175a:	94d6                	add	s1,s1,s5
    8000175c:	fc99f2e3          	bgeu	s3,s1,80001720 <copyin+0x28>
    80001760:	84ce                	mv	s1,s3
    80001762:	bf7d                	j	80001720 <copyin+0x28>
  }
  return 0;
    80001764:	4501                	li	a0,0
    80001766:	a021                	j	8000176e <copyin+0x76>
    80001768:	4501                	li	a0,0
}
    8000176a:	8082                	ret
      return -1;
    8000176c:	557d                	li	a0,-1
}
    8000176e:	60a6                	ld	ra,72(sp)
    80001770:	6406                	ld	s0,64(sp)
    80001772:	74e2                	ld	s1,56(sp)
    80001774:	7942                	ld	s2,48(sp)
    80001776:	79a2                	ld	s3,40(sp)
    80001778:	7a02                	ld	s4,32(sp)
    8000177a:	6ae2                	ld	s5,24(sp)
    8000177c:	6b42                	ld	s6,16(sp)
    8000177e:	6ba2                	ld	s7,8(sp)
    80001780:	6c02                	ld	s8,0(sp)
    80001782:	6161                	addi	sp,sp,80
    80001784:	8082                	ret

0000000080001786 <copyinstr>:
copyinstr(pagetable_t pagetable, char *dst, uint64 srcva, uint64 max)
{
  uint64 n, va0, pa0;
  int got_null = 0;

  while(got_null == 0 && max > 0){
    80001786:	c2dd                	beqz	a3,8000182c <copyinstr+0xa6>
{
    80001788:	715d                	addi	sp,sp,-80
    8000178a:	e486                	sd	ra,72(sp)
    8000178c:	e0a2                	sd	s0,64(sp)
    8000178e:	fc26                	sd	s1,56(sp)
    80001790:	f84a                	sd	s2,48(sp)
    80001792:	f44e                	sd	s3,40(sp)
    80001794:	f052                	sd	s4,32(sp)
    80001796:	ec56                	sd	s5,24(sp)
    80001798:	e85a                	sd	s6,16(sp)
    8000179a:	e45e                	sd	s7,8(sp)
    8000179c:	0880                	addi	s0,sp,80
    8000179e:	8a2a                	mv	s4,a0
    800017a0:	8b2e                	mv	s6,a1
    800017a2:	8bb2                	mv	s7,a2
    800017a4:	84b6                	mv	s1,a3
    va0 = PGROUNDDOWN(srcva);
    800017a6:	7afd                	lui	s5,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    800017a8:	6985                	lui	s3,0x1
    800017aa:	a02d                	j	800017d4 <copyinstr+0x4e>
      n = max;

    char *p = (char *) (pa0 + (srcva - va0));
    while(n > 0){
      if(*p == '\0'){
        *dst = '\0';
    800017ac:	00078023          	sb	zero,0(a5) # 1000 <_entry-0x7ffff000>
    800017b0:	4785                	li	a5,1
      dst++;
    }

    srcva = va0 + PGSIZE;
  }
  if(got_null){
    800017b2:	37fd                	addiw	a5,a5,-1
    800017b4:	0007851b          	sext.w	a0,a5
    return 0;
  } else {
    return -1;
  }
}
    800017b8:	60a6                	ld	ra,72(sp)
    800017ba:	6406                	ld	s0,64(sp)
    800017bc:	74e2                	ld	s1,56(sp)
    800017be:	7942                	ld	s2,48(sp)
    800017c0:	79a2                	ld	s3,40(sp)
    800017c2:	7a02                	ld	s4,32(sp)
    800017c4:	6ae2                	ld	s5,24(sp)
    800017c6:	6b42                	ld	s6,16(sp)
    800017c8:	6ba2                	ld	s7,8(sp)
    800017ca:	6161                	addi	sp,sp,80
    800017cc:	8082                	ret
    srcva = va0 + PGSIZE;
    800017ce:	01390bb3          	add	s7,s2,s3
  while(got_null == 0 && max > 0){
    800017d2:	c8a9                	beqz	s1,80001824 <copyinstr+0x9e>
    va0 = PGROUNDDOWN(srcva);
    800017d4:	015bf933          	and	s2,s7,s5
    pa0 = walkaddr(pagetable, va0);
    800017d8:	85ca                	mv	a1,s2
    800017da:	8552                	mv	a0,s4
    800017dc:	00000097          	auipc	ra,0x0
    800017e0:	880080e7          	jalr	-1920(ra) # 8000105c <walkaddr>
    if(pa0 == 0)
    800017e4:	c131                	beqz	a0,80001828 <copyinstr+0xa2>
    n = PGSIZE - (srcva - va0);
    800017e6:	417906b3          	sub	a3,s2,s7
    800017ea:	96ce                	add	a3,a3,s3
    800017ec:	00d4f363          	bgeu	s1,a3,800017f2 <copyinstr+0x6c>
    800017f0:	86a6                	mv	a3,s1
    char *p = (char *) (pa0 + (srcva - va0));
    800017f2:	955e                	add	a0,a0,s7
    800017f4:	41250533          	sub	a0,a0,s2
    while(n > 0){
    800017f8:	daf9                	beqz	a3,800017ce <copyinstr+0x48>
    800017fa:	87da                	mv	a5,s6
      if(*p == '\0'){
    800017fc:	41650633          	sub	a2,a0,s6
    80001800:	fff48593          	addi	a1,s1,-1
    80001804:	95da                	add	a1,a1,s6
    while(n > 0){
    80001806:	96da                	add	a3,a3,s6
      if(*p == '\0'){
    80001808:	00f60733          	add	a4,a2,a5
    8000180c:	00074703          	lbu	a4,0(a4) # fffffffffffff000 <end+0xffffffff7ffdc480>
    80001810:	df51                	beqz	a4,800017ac <copyinstr+0x26>
        *dst = *p;
    80001812:	00e78023          	sb	a4,0(a5)
      --max;
    80001816:	40f584b3          	sub	s1,a1,a5
      dst++;
    8000181a:	0785                	addi	a5,a5,1
    while(n > 0){
    8000181c:	fed796e3          	bne	a5,a3,80001808 <copyinstr+0x82>
      dst++;
    80001820:	8b3e                	mv	s6,a5
    80001822:	b775                	j	800017ce <copyinstr+0x48>
    80001824:	4781                	li	a5,0
    80001826:	b771                	j	800017b2 <copyinstr+0x2c>
      return -1;
    80001828:	557d                	li	a0,-1
    8000182a:	b779                	j	800017b8 <copyinstr+0x32>
  int got_null = 0;
    8000182c:	4781                	li	a5,0
  if(got_null){
    8000182e:	37fd                	addiw	a5,a5,-1
    80001830:	0007851b          	sext.w	a0,a5
}
    80001834:	8082                	ret

0000000080001836 <proc_mapstacks>:

// Allocate a page for each process's kernel stack.
// Map it high in memory, followed by an invalid
// guard page.
void proc_mapstacks(pagetable_t kpgtbl)
{
    80001836:	7139                	addi	sp,sp,-64
    80001838:	fc06                	sd	ra,56(sp)
    8000183a:	f822                	sd	s0,48(sp)
    8000183c:	f426                	sd	s1,40(sp)
    8000183e:	f04a                	sd	s2,32(sp)
    80001840:	ec4e                	sd	s3,24(sp)
    80001842:	e852                	sd	s4,16(sp)
    80001844:	e456                	sd	s5,8(sp)
    80001846:	e05a                	sd	s6,0(sp)
    80001848:	0080                	addi	s0,sp,64
    8000184a:	89aa                	mv	s3,a0
  struct proc *p;

  for (p = proc; p < &proc[NPROC]; p++)
    8000184c:	0000f497          	auipc	s1,0xf
    80001850:	75448493          	addi	s1,s1,1876 # 80010fa0 <proc>
  {
    char *pa = kalloc();
    if (pa == 0)
      panic("kalloc");
    uint64 va = KSTACK((int)(p - proc));
    80001854:	8b26                	mv	s6,s1
    80001856:	00006a97          	auipc	s5,0x6
    8000185a:	7aaa8a93          	addi	s5,s5,1962 # 80008000 <etext>
    8000185e:	04000937          	lui	s2,0x4000
    80001862:	197d                	addi	s2,s2,-1 # 3ffffff <_entry-0x7c000001>
    80001864:	0932                	slli	s2,s2,0xc
  for (p = proc; p < &proc[NPROC]; p++)
    80001866:	00016a17          	auipc	s4,0x16
    8000186a:	f3aa0a13          	addi	s4,s4,-198 # 800177a0 <tickslock>
    char *pa = kalloc();
    8000186e:	fffff097          	auipc	ra,0xfffff
    80001872:	278080e7          	jalr	632(ra) # 80000ae6 <kalloc>
    80001876:	862a                	mv	a2,a0
    if (pa == 0)
    80001878:	c131                	beqz	a0,800018bc <proc_mapstacks+0x86>
    uint64 va = KSTACK((int)(p - proc));
    8000187a:	416485b3          	sub	a1,s1,s6
    8000187e:	8595                	srai	a1,a1,0x5
    80001880:	000ab783          	ld	a5,0(s5)
    80001884:	02f585b3          	mul	a1,a1,a5
    80001888:	2585                	addiw	a1,a1,1
    8000188a:	00d5959b          	slliw	a1,a1,0xd
    kvmmap(kpgtbl, va, (uint64)pa, PGSIZE, PTE_R | PTE_W);
    8000188e:	4719                	li	a4,6
    80001890:	6685                	lui	a3,0x1
    80001892:	40b905b3          	sub	a1,s2,a1
    80001896:	854e                	mv	a0,s3
    80001898:	00000097          	auipc	ra,0x0
    8000189c:	8a6080e7          	jalr	-1882(ra) # 8000113e <kvmmap>
  for (p = proc; p < &proc[NPROC]; p++)
    800018a0:	1a048493          	addi	s1,s1,416
    800018a4:	fd4495e3          	bne	s1,s4,8000186e <proc_mapstacks+0x38>
  }
}
    800018a8:	70e2                	ld	ra,56(sp)
    800018aa:	7442                	ld	s0,48(sp)
    800018ac:	74a2                	ld	s1,40(sp)
    800018ae:	7902                	ld	s2,32(sp)
    800018b0:	69e2                	ld	s3,24(sp)
    800018b2:	6a42                	ld	s4,16(sp)
    800018b4:	6aa2                	ld	s5,8(sp)
    800018b6:	6b02                	ld	s6,0(sp)
    800018b8:	6121                	addi	sp,sp,64
    800018ba:	8082                	ret
      panic("kalloc");
    800018bc:	00007517          	auipc	a0,0x7
    800018c0:	91c50513          	addi	a0,a0,-1764 # 800081d8 <digits+0x198>
    800018c4:	fffff097          	auipc	ra,0xfffff
    800018c8:	c7c080e7          	jalr	-900(ra) # 80000540 <panic>

00000000800018cc <procinit>:

// initialize the proc table.
void procinit(void)
{
    800018cc:	7139                	addi	sp,sp,-64
    800018ce:	fc06                	sd	ra,56(sp)
    800018d0:	f822                	sd	s0,48(sp)
    800018d2:	f426                	sd	s1,40(sp)
    800018d4:	f04a                	sd	s2,32(sp)
    800018d6:	ec4e                	sd	s3,24(sp)
    800018d8:	e852                	sd	s4,16(sp)
    800018da:	e456                	sd	s5,8(sp)
    800018dc:	e05a                	sd	s6,0(sp)
    800018de:	0080                	addi	s0,sp,64
  struct proc *p;

  initlock(&pid_lock, "nextpid");
    800018e0:	00007597          	auipc	a1,0x7
    800018e4:	90058593          	addi	a1,a1,-1792 # 800081e0 <digits+0x1a0>
    800018e8:	0000f517          	auipc	a0,0xf
    800018ec:	28850513          	addi	a0,a0,648 # 80010b70 <pid_lock>
    800018f0:	fffff097          	auipc	ra,0xfffff
    800018f4:	256080e7          	jalr	598(ra) # 80000b46 <initlock>
  initlock(&wait_lock, "wait_lock");
    800018f8:	00007597          	auipc	a1,0x7
    800018fc:	8f058593          	addi	a1,a1,-1808 # 800081e8 <digits+0x1a8>
    80001900:	0000f517          	auipc	a0,0xf
    80001904:	28850513          	addi	a0,a0,648 # 80010b88 <wait_lock>
    80001908:	fffff097          	auipc	ra,0xfffff
    8000190c:	23e080e7          	jalr	574(ra) # 80000b46 <initlock>
  for (p = proc; p < &proc[NPROC]; p++)
    80001910:	0000f497          	auipc	s1,0xf
    80001914:	69048493          	addi	s1,s1,1680 # 80010fa0 <proc>
  {
    initlock(&p->lock, "proc");
    80001918:	00007b17          	auipc	s6,0x7
    8000191c:	8e0b0b13          	addi	s6,s6,-1824 # 800081f8 <digits+0x1b8>
    p->state = UNUSED;
    p->kstack = KSTACK((int)(p - proc));
    80001920:	8aa6                	mv	s5,s1
    80001922:	00006a17          	auipc	s4,0x6
    80001926:	6dea0a13          	addi	s4,s4,1758 # 80008000 <etext>
    8000192a:	04000937          	lui	s2,0x4000
    8000192e:	197d                	addi	s2,s2,-1 # 3ffffff <_entry-0x7c000001>
    80001930:	0932                	slli	s2,s2,0xc
  for (p = proc; p < &proc[NPROC]; p++)
    80001932:	00016997          	auipc	s3,0x16
    80001936:	e6e98993          	addi	s3,s3,-402 # 800177a0 <tickslock>
    initlock(&p->lock, "proc");
    8000193a:	85da                	mv	a1,s6
    8000193c:	8526                	mv	a0,s1
    8000193e:	fffff097          	auipc	ra,0xfffff
    80001942:	208080e7          	jalr	520(ra) # 80000b46 <initlock>
    p->state = UNUSED;
    80001946:	0004ac23          	sw	zero,24(s1)
    p->kstack = KSTACK((int)(p - proc));
    8000194a:	415487b3          	sub	a5,s1,s5
    8000194e:	8795                	srai	a5,a5,0x5
    80001950:	000a3703          	ld	a4,0(s4)
    80001954:	02e787b3          	mul	a5,a5,a4
    80001958:	2785                	addiw	a5,a5,1
    8000195a:	00d7979b          	slliw	a5,a5,0xd
    8000195e:	40f907b3          	sub	a5,s2,a5
    80001962:	f0bc                	sd	a5,96(s1)
  for (p = proc; p < &proc[NPROC]; p++)
    80001964:	1a048493          	addi	s1,s1,416
    80001968:	fd3499e3          	bne	s1,s3,8000193a <procinit+0x6e>
  }
}
    8000196c:	70e2                	ld	ra,56(sp)
    8000196e:	7442                	ld	s0,48(sp)
    80001970:	74a2                	ld	s1,40(sp)
    80001972:	7902                	ld	s2,32(sp)
    80001974:	69e2                	ld	s3,24(sp)
    80001976:	6a42                	ld	s4,16(sp)
    80001978:	6aa2                	ld	s5,8(sp)
    8000197a:	6b02                	ld	s6,0(sp)
    8000197c:	6121                	addi	sp,sp,64
    8000197e:	8082                	ret

0000000080001980 <cpuid>:

// Must be called with interrupts disabled,
// to prevent race with process being moved
// to a different CPU.
int cpuid()
{
    80001980:	1141                	addi	sp,sp,-16
    80001982:	e422                	sd	s0,8(sp)
    80001984:	0800                	addi	s0,sp,16
  asm volatile("mv %0, tp" : "=r" (x) );
    80001986:	8512                	mv	a0,tp
  int id = r_tp();
  return id;
}
    80001988:	2501                	sext.w	a0,a0
    8000198a:	6422                	ld	s0,8(sp)
    8000198c:	0141                	addi	sp,sp,16
    8000198e:	8082                	ret

0000000080001990 <mycpu>:

// Return this CPU's cpu struct.
// Interrupts must be disabled.
struct cpu *
mycpu(void)
{
    80001990:	1141                	addi	sp,sp,-16
    80001992:	e422                	sd	s0,8(sp)
    80001994:	0800                	addi	s0,sp,16
    80001996:	8792                	mv	a5,tp
  int id = cpuid();
  struct cpu *c = &cpus[id];
    80001998:	2781                	sext.w	a5,a5
    8000199a:	079e                	slli	a5,a5,0x7
  return c;
}
    8000199c:	0000f517          	auipc	a0,0xf
    800019a0:	20450513          	addi	a0,a0,516 # 80010ba0 <cpus>
    800019a4:	953e                	add	a0,a0,a5
    800019a6:	6422                	ld	s0,8(sp)
    800019a8:	0141                	addi	sp,sp,16
    800019aa:	8082                	ret

00000000800019ac <myproc>:

// Return the current struct proc *, or zero if none.
struct proc *
myproc(void)
{
    800019ac:	1101                	addi	sp,sp,-32
    800019ae:	ec06                	sd	ra,24(sp)
    800019b0:	e822                	sd	s0,16(sp)
    800019b2:	e426                	sd	s1,8(sp)
    800019b4:	1000                	addi	s0,sp,32
  push_off();
    800019b6:	fffff097          	auipc	ra,0xfffff
    800019ba:	1d4080e7          	jalr	468(ra) # 80000b8a <push_off>
    800019be:	8792                	mv	a5,tp
  struct cpu *c = mycpu();
  struct proc *p = c->proc;
    800019c0:	2781                	sext.w	a5,a5
    800019c2:	079e                	slli	a5,a5,0x7
    800019c4:	0000f717          	auipc	a4,0xf
    800019c8:	1ac70713          	addi	a4,a4,428 # 80010b70 <pid_lock>
    800019cc:	97ba                	add	a5,a5,a4
    800019ce:	7b84                	ld	s1,48(a5)
  pop_off();
    800019d0:	fffff097          	auipc	ra,0xfffff
    800019d4:	25a080e7          	jalr	602(ra) # 80000c2a <pop_off>
  return p;
}
    800019d8:	8526                	mv	a0,s1
    800019da:	60e2                	ld	ra,24(sp)
    800019dc:	6442                	ld	s0,16(sp)
    800019de:	64a2                	ld	s1,8(sp)
    800019e0:	6105                	addi	sp,sp,32
    800019e2:	8082                	ret

00000000800019e4 <forkret>:
}

// A fork child's very first scheduling by scheduler()
// will swtch to forkret.
void forkret(void)
{
    800019e4:	1141                	addi	sp,sp,-16
    800019e6:	e406                	sd	ra,8(sp)
    800019e8:	e022                	sd	s0,0(sp)
    800019ea:	0800                	addi	s0,sp,16
  static int first = 1;

  // Still holding p->lock from scheduler.
  release(&myproc()->lock);
    800019ec:	00000097          	auipc	ra,0x0
    800019f0:	fc0080e7          	jalr	-64(ra) # 800019ac <myproc>
    800019f4:	fffff097          	auipc	ra,0xfffff
    800019f8:	296080e7          	jalr	662(ra) # 80000c8a <release>

  if (first)
    800019fc:	00007797          	auipc	a5,0x7
    80001a00:	e647a783          	lw	a5,-412(a5) # 80008860 <first.1>
    80001a04:	eb89                	bnez	a5,80001a16 <forkret+0x32>
    // be run from main().
    first = 0;
    fsinit(ROOTDEV);
  }

  usertrapret();
    80001a06:	00001097          	auipc	ra,0x1
    80001a0a:	f08080e7          	jalr	-248(ra) # 8000290e <usertrapret>
}
    80001a0e:	60a2                	ld	ra,8(sp)
    80001a10:	6402                	ld	s0,0(sp)
    80001a12:	0141                	addi	sp,sp,16
    80001a14:	8082                	ret
    first = 0;
    80001a16:	00007797          	auipc	a5,0x7
    80001a1a:	e407a523          	sw	zero,-438(a5) # 80008860 <first.1>
    fsinit(ROOTDEV);
    80001a1e:	4505                	li	a0,1
    80001a20:	00002097          	auipc	ra,0x2
    80001a24:	0ee080e7          	jalr	238(ra) # 80003b0e <fsinit>
    80001a28:	bff9                	j	80001a06 <forkret+0x22>

0000000080001a2a <allocpid>:
{
    80001a2a:	1101                	addi	sp,sp,-32
    80001a2c:	ec06                	sd	ra,24(sp)
    80001a2e:	e822                	sd	s0,16(sp)
    80001a30:	e426                	sd	s1,8(sp)
    80001a32:	e04a                	sd	s2,0(sp)
    80001a34:	1000                	addi	s0,sp,32
  acquire(&pid_lock);
    80001a36:	0000f917          	auipc	s2,0xf
    80001a3a:	13a90913          	addi	s2,s2,314 # 80010b70 <pid_lock>
    80001a3e:	854a                	mv	a0,s2
    80001a40:	fffff097          	auipc	ra,0xfffff
    80001a44:	196080e7          	jalr	406(ra) # 80000bd6 <acquire>
  pid = nextpid;
    80001a48:	00007797          	auipc	a5,0x7
    80001a4c:	e1c78793          	addi	a5,a5,-484 # 80008864 <nextpid>
    80001a50:	4384                	lw	s1,0(a5)
  nextpid = nextpid + 1;
    80001a52:	0014871b          	addiw	a4,s1,1
    80001a56:	c398                	sw	a4,0(a5)
  release(&pid_lock);
    80001a58:	854a                	mv	a0,s2
    80001a5a:	fffff097          	auipc	ra,0xfffff
    80001a5e:	230080e7          	jalr	560(ra) # 80000c8a <release>
}
    80001a62:	8526                	mv	a0,s1
    80001a64:	60e2                	ld	ra,24(sp)
    80001a66:	6442                	ld	s0,16(sp)
    80001a68:	64a2                	ld	s1,8(sp)
    80001a6a:	6902                	ld	s2,0(sp)
    80001a6c:	6105                	addi	sp,sp,32
    80001a6e:	8082                	ret

0000000080001a70 <proc_pagetable>:
{
    80001a70:	1101                	addi	sp,sp,-32
    80001a72:	ec06                	sd	ra,24(sp)
    80001a74:	e822                	sd	s0,16(sp)
    80001a76:	e426                	sd	s1,8(sp)
    80001a78:	e04a                	sd	s2,0(sp)
    80001a7a:	1000                	addi	s0,sp,32
    80001a7c:	892a                	mv	s2,a0
  pagetable = uvmcreate();
    80001a7e:	00000097          	auipc	ra,0x0
    80001a82:	8aa080e7          	jalr	-1878(ra) # 80001328 <uvmcreate>
    80001a86:	84aa                	mv	s1,a0
  if (pagetable == 0)
    80001a88:	c121                	beqz	a0,80001ac8 <proc_pagetable+0x58>
  if (mappages(pagetable, TRAMPOLINE, PGSIZE,
    80001a8a:	4729                	li	a4,10
    80001a8c:	00005697          	auipc	a3,0x5
    80001a90:	57468693          	addi	a3,a3,1396 # 80007000 <_trampoline>
    80001a94:	6605                	lui	a2,0x1
    80001a96:	040005b7          	lui	a1,0x4000
    80001a9a:	15fd                	addi	a1,a1,-1 # 3ffffff <_entry-0x7c000001>
    80001a9c:	05b2                	slli	a1,a1,0xc
    80001a9e:	fffff097          	auipc	ra,0xfffff
    80001aa2:	600080e7          	jalr	1536(ra) # 8000109e <mappages>
    80001aa6:	02054863          	bltz	a0,80001ad6 <proc_pagetable+0x66>
  if (mappages(pagetable, TRAPFRAME, PGSIZE,
    80001aaa:	4719                	li	a4,6
    80001aac:	07893683          	ld	a3,120(s2)
    80001ab0:	6605                	lui	a2,0x1
    80001ab2:	020005b7          	lui	a1,0x2000
    80001ab6:	15fd                	addi	a1,a1,-1 # 1ffffff <_entry-0x7e000001>
    80001ab8:	05b6                	slli	a1,a1,0xd
    80001aba:	8526                	mv	a0,s1
    80001abc:	fffff097          	auipc	ra,0xfffff
    80001ac0:	5e2080e7          	jalr	1506(ra) # 8000109e <mappages>
    80001ac4:	02054163          	bltz	a0,80001ae6 <proc_pagetable+0x76>
}
    80001ac8:	8526                	mv	a0,s1
    80001aca:	60e2                	ld	ra,24(sp)
    80001acc:	6442                	ld	s0,16(sp)
    80001ace:	64a2                	ld	s1,8(sp)
    80001ad0:	6902                	ld	s2,0(sp)
    80001ad2:	6105                	addi	sp,sp,32
    80001ad4:	8082                	ret
    uvmfree(pagetable, 0);
    80001ad6:	4581                	li	a1,0
    80001ad8:	8526                	mv	a0,s1
    80001ada:	00000097          	auipc	ra,0x0
    80001ade:	a54080e7          	jalr	-1452(ra) # 8000152e <uvmfree>
    return 0;
    80001ae2:	4481                	li	s1,0
    80001ae4:	b7d5                	j	80001ac8 <proc_pagetable+0x58>
    uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001ae6:	4681                	li	a3,0
    80001ae8:	4605                	li	a2,1
    80001aea:	040005b7          	lui	a1,0x4000
    80001aee:	15fd                	addi	a1,a1,-1 # 3ffffff <_entry-0x7c000001>
    80001af0:	05b2                	slli	a1,a1,0xc
    80001af2:	8526                	mv	a0,s1
    80001af4:	fffff097          	auipc	ra,0xfffff
    80001af8:	770080e7          	jalr	1904(ra) # 80001264 <uvmunmap>
    uvmfree(pagetable, 0);
    80001afc:	4581                	li	a1,0
    80001afe:	8526                	mv	a0,s1
    80001b00:	00000097          	auipc	ra,0x0
    80001b04:	a2e080e7          	jalr	-1490(ra) # 8000152e <uvmfree>
    return 0;
    80001b08:	4481                	li	s1,0
    80001b0a:	bf7d                	j	80001ac8 <proc_pagetable+0x58>

0000000080001b0c <proc_freepagetable>:
{
    80001b0c:	1101                	addi	sp,sp,-32
    80001b0e:	ec06                	sd	ra,24(sp)
    80001b10:	e822                	sd	s0,16(sp)
    80001b12:	e426                	sd	s1,8(sp)
    80001b14:	e04a                	sd	s2,0(sp)
    80001b16:	1000                	addi	s0,sp,32
    80001b18:	84aa                	mv	s1,a0
    80001b1a:	892e                	mv	s2,a1
  uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001b1c:	4681                	li	a3,0
    80001b1e:	4605                	li	a2,1
    80001b20:	040005b7          	lui	a1,0x4000
    80001b24:	15fd                	addi	a1,a1,-1 # 3ffffff <_entry-0x7c000001>
    80001b26:	05b2                	slli	a1,a1,0xc
    80001b28:	fffff097          	auipc	ra,0xfffff
    80001b2c:	73c080e7          	jalr	1852(ra) # 80001264 <uvmunmap>
  uvmunmap(pagetable, TRAPFRAME, 1, 0);
    80001b30:	4681                	li	a3,0
    80001b32:	4605                	li	a2,1
    80001b34:	020005b7          	lui	a1,0x2000
    80001b38:	15fd                	addi	a1,a1,-1 # 1ffffff <_entry-0x7e000001>
    80001b3a:	05b6                	slli	a1,a1,0xd
    80001b3c:	8526                	mv	a0,s1
    80001b3e:	fffff097          	auipc	ra,0xfffff
    80001b42:	726080e7          	jalr	1830(ra) # 80001264 <uvmunmap>
  uvmfree(pagetable, sz);
    80001b46:	85ca                	mv	a1,s2
    80001b48:	8526                	mv	a0,s1
    80001b4a:	00000097          	auipc	ra,0x0
    80001b4e:	9e4080e7          	jalr	-1564(ra) # 8000152e <uvmfree>
}
    80001b52:	60e2                	ld	ra,24(sp)
    80001b54:	6442                	ld	s0,16(sp)
    80001b56:	64a2                	ld	s1,8(sp)
    80001b58:	6902                	ld	s2,0(sp)
    80001b5a:	6105                	addi	sp,sp,32
    80001b5c:	8082                	ret

0000000080001b5e <freeproc>:
{
    80001b5e:	1101                	addi	sp,sp,-32
    80001b60:	ec06                	sd	ra,24(sp)
    80001b62:	e822                	sd	s0,16(sp)
    80001b64:	e426                	sd	s1,8(sp)
    80001b66:	1000                	addi	s0,sp,32
    80001b68:	84aa                	mv	s1,a0
  if (p->trapframe)
    80001b6a:	7d28                	ld	a0,120(a0)
    80001b6c:	c509                	beqz	a0,80001b76 <freeproc+0x18>
    kfree((void *)p->trapframe);
    80001b6e:	fffff097          	auipc	ra,0xfffff
    80001b72:	e7a080e7          	jalr	-390(ra) # 800009e8 <kfree>
  p->trapframe = 0;
    80001b76:	0604bc23          	sd	zero,120(s1)
  if (p->pagetable)
    80001b7a:	78a8                	ld	a0,112(s1)
    80001b7c:	c511                	beqz	a0,80001b88 <freeproc+0x2a>
    proc_freepagetable(p->pagetable, p->sz);
    80001b7e:	74ac                	ld	a1,104(s1)
    80001b80:	00000097          	auipc	ra,0x0
    80001b84:	f8c080e7          	jalr	-116(ra) # 80001b0c <proc_freepagetable>
  p->pagetable = 0;
    80001b88:	0604b823          	sd	zero,112(s1)
  p->sz = 0;
    80001b8c:	0604b423          	sd	zero,104(s1)
  p->pid = 0;
    80001b90:	0204a823          	sw	zero,48(s1)
  p->parent = 0;
    80001b94:	0204bc23          	sd	zero,56(s1)
  p->name[0] = 0;
    80001b98:	16048c23          	sb	zero,376(s1)
  p->chan = 0;
    80001b9c:	0204b023          	sd	zero,32(s1)
  p->killed = 0;
    80001ba0:	0204a423          	sw	zero,40(s1)
  p->xstate = 0;
    80001ba4:	0204a623          	sw	zero,44(s1)
  p->state = UNUSED;
    80001ba8:	0004ac23          	sw	zero,24(s1)
  kfree((void *)p->alarm_saving_tf);
    80001bac:	68a8                	ld	a0,80(s1)
    80001bae:	fffff097          	auipc	ra,0xfffff
    80001bb2:	e3a080e7          	jalr	-454(ra) # 800009e8 <kfree>
  p->que_no = 0;
    80001bb6:	1804ac23          	sw	zero,408(s1)
}
    80001bba:	60e2                	ld	ra,24(sp)
    80001bbc:	6442                	ld	s0,16(sp)
    80001bbe:	64a2                	ld	s1,8(sp)
    80001bc0:	6105                	addi	sp,sp,32
    80001bc2:	8082                	ret

0000000080001bc4 <allocproc>:
{
    80001bc4:	1101                	addi	sp,sp,-32
    80001bc6:	ec06                	sd	ra,24(sp)
    80001bc8:	e822                	sd	s0,16(sp)
    80001bca:	e426                	sd	s1,8(sp)
    80001bcc:	e04a                	sd	s2,0(sp)
    80001bce:	1000                	addi	s0,sp,32
  for (p = proc; p < &proc[NPROC]; p++)
    80001bd0:	0000f497          	auipc	s1,0xf
    80001bd4:	3d048493          	addi	s1,s1,976 # 80010fa0 <proc>
    80001bd8:	00016917          	auipc	s2,0x16
    80001bdc:	bc890913          	addi	s2,s2,-1080 # 800177a0 <tickslock>
    acquire(&p->lock);
    80001be0:	8526                	mv	a0,s1
    80001be2:	fffff097          	auipc	ra,0xfffff
    80001be6:	ff4080e7          	jalr	-12(ra) # 80000bd6 <acquire>
    if (p->state == UNUSED)
    80001bea:	4c9c                	lw	a5,24(s1)
    80001bec:	cf81                	beqz	a5,80001c04 <allocproc+0x40>
      release(&p->lock);
    80001bee:	8526                	mv	a0,s1
    80001bf0:	fffff097          	auipc	ra,0xfffff
    80001bf4:	09a080e7          	jalr	154(ra) # 80000c8a <release>
  for (p = proc; p < &proc[NPROC]; p++)
    80001bf8:	1a048493          	addi	s1,s1,416
    80001bfc:	ff2492e3          	bne	s1,s2,80001be0 <allocproc+0x1c>
  return 0;
    80001c00:	4481                	li	s1,0
    80001c02:	a051                	j	80001c86 <allocproc+0xc2>
  p->pid = allocpid();
    80001c04:	00000097          	auipc	ra,0x0
    80001c08:	e26080e7          	jalr	-474(ra) # 80001a2a <allocpid>
    80001c0c:	d888                	sw	a0,48(s1)
  p->state = USED;
    80001c0e:	4785                	li	a5,1
    80001c10:	cc9c                	sw	a5,24(s1)
  if ((p->trapframe = (struct trapframe *)kalloc()) == 0)
    80001c12:	fffff097          	auipc	ra,0xfffff
    80001c16:	ed4080e7          	jalr	-300(ra) # 80000ae6 <kalloc>
    80001c1a:	892a                	mv	s2,a0
    80001c1c:	fca8                	sd	a0,120(s1)
    80001c1e:	c93d                	beqz	a0,80001c94 <allocproc+0xd0>
  p->count_of_read = 0; // getreadcount
    80001c20:	0204aa23          	sw	zero,52(s1)
  p->current_no_of_ticks = 0;                        // sigalarm
    80001c24:	0404a623          	sw	zero,76(s1)
  p->alarm_saving_tf = (struct trapframe *)kalloc(); // sigalarm
    80001c28:	fffff097          	auipc	ra,0xfffff
    80001c2c:	ebe080e7          	jalr	-322(ra) # 80000ae6 <kalloc>
    80001c30:	e8a8                	sd	a0,80(s1)
  p->pagetable = proc_pagetable(p);
    80001c32:	8526                	mv	a0,s1
    80001c34:	00000097          	auipc	ra,0x0
    80001c38:	e3c080e7          	jalr	-452(ra) # 80001a70 <proc_pagetable>
    80001c3c:	892a                	mv	s2,a0
    80001c3e:	f8a8                	sd	a0,112(s1)
  if (p->pagetable == 0)
    80001c40:	c535                	beqz	a0,80001cac <allocproc+0xe8>
  memset(&p->context, 0, sizeof(p->context));
    80001c42:	07000613          	li	a2,112
    80001c46:	4581                	li	a1,0
    80001c48:	08048513          	addi	a0,s1,128
    80001c4c:	fffff097          	auipc	ra,0xfffff
    80001c50:	086080e7          	jalr	134(ra) # 80000cd2 <memset>
  p->context.ra = (uint64)forkret;
    80001c54:	00000797          	auipc	a5,0x0
    80001c58:	d9078793          	addi	a5,a5,-624 # 800019e4 <forkret>
    80001c5c:	e0dc                	sd	a5,128(s1)
  p->context.sp = p->kstack + PGSIZE;
    80001c5e:	70bc                	ld	a5,96(s1)
    80001c60:	6705                	lui	a4,0x1
    80001c62:	97ba                	add	a5,a5,a4
    80001c64:	e4dc                	sd	a5,136(s1)
  p->rtime = 0;
    80001c66:	1804a423          	sw	zero,392(s1)
  p->etime = 0;
    80001c6a:	1804a823          	sw	zero,400(s1)
  p->ctime = ticks;
    80001c6e:	00007797          	auipc	a5,0x7
    80001c72:	c927a783          	lw	a5,-878(a5) # 80008900 <ticks>
    80001c76:	18f4a623          	sw	a5,396(s1)
  p->in_time = ticks;
    80001c7a:	18f4aa23          	sw	a5,404(s1)
  p->counter_of_ticks = 0;
    80001c7e:	1804ae23          	sw	zero,412(s1)
  p->que_no = 0;
    80001c82:	1804ac23          	sw	zero,408(s1)
}
    80001c86:	8526                	mv	a0,s1
    80001c88:	60e2                	ld	ra,24(sp)
    80001c8a:	6442                	ld	s0,16(sp)
    80001c8c:	64a2                	ld	s1,8(sp)
    80001c8e:	6902                	ld	s2,0(sp)
    80001c90:	6105                	addi	sp,sp,32
    80001c92:	8082                	ret
    freeproc(p);
    80001c94:	8526                	mv	a0,s1
    80001c96:	00000097          	auipc	ra,0x0
    80001c9a:	ec8080e7          	jalr	-312(ra) # 80001b5e <freeproc>
    release(&p->lock);
    80001c9e:	8526                	mv	a0,s1
    80001ca0:	fffff097          	auipc	ra,0xfffff
    80001ca4:	fea080e7          	jalr	-22(ra) # 80000c8a <release>
    return 0;
    80001ca8:	84ca                	mv	s1,s2
    80001caa:	bff1                	j	80001c86 <allocproc+0xc2>
    freeproc(p);
    80001cac:	8526                	mv	a0,s1
    80001cae:	00000097          	auipc	ra,0x0
    80001cb2:	eb0080e7          	jalr	-336(ra) # 80001b5e <freeproc>
    release(&p->lock);
    80001cb6:	8526                	mv	a0,s1
    80001cb8:	fffff097          	auipc	ra,0xfffff
    80001cbc:	fd2080e7          	jalr	-46(ra) # 80000c8a <release>
    return 0;
    80001cc0:	84ca                	mv	s1,s2
    80001cc2:	b7d1                	j	80001c86 <allocproc+0xc2>

0000000080001cc4 <userinit>:
{
    80001cc4:	1101                	addi	sp,sp,-32
    80001cc6:	ec06                	sd	ra,24(sp)
    80001cc8:	e822                	sd	s0,16(sp)
    80001cca:	e426                	sd	s1,8(sp)
    80001ccc:	1000                	addi	s0,sp,32
  p = allocproc();
    80001cce:	00000097          	auipc	ra,0x0
    80001cd2:	ef6080e7          	jalr	-266(ra) # 80001bc4 <allocproc>
    80001cd6:	84aa                	mv	s1,a0
  initproc = p;
    80001cd8:	00007797          	auipc	a5,0x7
    80001cdc:	c2a7b023          	sd	a0,-992(a5) # 800088f8 <initproc>
  uvmfirst(p->pagetable, initcode, sizeof(initcode));
    80001ce0:	03400613          	li	a2,52
    80001ce4:	00007597          	auipc	a1,0x7
    80001ce8:	b8c58593          	addi	a1,a1,-1140 # 80008870 <initcode>
    80001cec:	7928                	ld	a0,112(a0)
    80001cee:	fffff097          	auipc	ra,0xfffff
    80001cf2:	668080e7          	jalr	1640(ra) # 80001356 <uvmfirst>
  p->sz = PGSIZE;
    80001cf6:	6785                	lui	a5,0x1
    80001cf8:	f4bc                	sd	a5,104(s1)
  p->trapframe->epc = 0;     // user program counter
    80001cfa:	7cb8                	ld	a4,120(s1)
    80001cfc:	00073c23          	sd	zero,24(a4) # 1018 <_entry-0x7fffefe8>
  p->trapframe->sp = PGSIZE; // user stack pointer
    80001d00:	7cb8                	ld	a4,120(s1)
    80001d02:	fb1c                	sd	a5,48(a4)
  safestrcpy(p->name, "initcode", sizeof(p->name));
    80001d04:	4641                	li	a2,16
    80001d06:	00006597          	auipc	a1,0x6
    80001d0a:	4fa58593          	addi	a1,a1,1274 # 80008200 <digits+0x1c0>
    80001d0e:	17848513          	addi	a0,s1,376
    80001d12:	fffff097          	auipc	ra,0xfffff
    80001d16:	10a080e7          	jalr	266(ra) # 80000e1c <safestrcpy>
  p->cwd = namei("/");
    80001d1a:	00006517          	auipc	a0,0x6
    80001d1e:	4f650513          	addi	a0,a0,1270 # 80008210 <digits+0x1d0>
    80001d22:	00003097          	auipc	ra,0x3
    80001d26:	816080e7          	jalr	-2026(ra) # 80004538 <namei>
    80001d2a:	16a4b823          	sd	a0,368(s1)
  p->state = RUNNABLE;
    80001d2e:	478d                	li	a5,3
    80001d30:	cc9c                	sw	a5,24(s1)
  release(&p->lock);
    80001d32:	8526                	mv	a0,s1
    80001d34:	fffff097          	auipc	ra,0xfffff
    80001d38:	f56080e7          	jalr	-170(ra) # 80000c8a <release>
}
    80001d3c:	60e2                	ld	ra,24(sp)
    80001d3e:	6442                	ld	s0,16(sp)
    80001d40:	64a2                	ld	s1,8(sp)
    80001d42:	6105                	addi	sp,sp,32
    80001d44:	8082                	ret

0000000080001d46 <growproc>:
{
    80001d46:	1101                	addi	sp,sp,-32
    80001d48:	ec06                	sd	ra,24(sp)
    80001d4a:	e822                	sd	s0,16(sp)
    80001d4c:	e426                	sd	s1,8(sp)
    80001d4e:	e04a                	sd	s2,0(sp)
    80001d50:	1000                	addi	s0,sp,32
    80001d52:	892a                	mv	s2,a0
  struct proc *p = myproc();
    80001d54:	00000097          	auipc	ra,0x0
    80001d58:	c58080e7          	jalr	-936(ra) # 800019ac <myproc>
    80001d5c:	84aa                	mv	s1,a0
  sz = p->sz;
    80001d5e:	752c                	ld	a1,104(a0)
  if (n > 0)
    80001d60:	01204c63          	bgtz	s2,80001d78 <growproc+0x32>
  else if (n < 0)
    80001d64:	02094663          	bltz	s2,80001d90 <growproc+0x4a>
  p->sz = sz;
    80001d68:	f4ac                	sd	a1,104(s1)
  return 0;
    80001d6a:	4501                	li	a0,0
}
    80001d6c:	60e2                	ld	ra,24(sp)
    80001d6e:	6442                	ld	s0,16(sp)
    80001d70:	64a2                	ld	s1,8(sp)
    80001d72:	6902                	ld	s2,0(sp)
    80001d74:	6105                	addi	sp,sp,32
    80001d76:	8082                	ret
    if ((sz = uvmalloc(p->pagetable, sz, sz + n, PTE_W)) == 0)
    80001d78:	4691                	li	a3,4
    80001d7a:	00b90633          	add	a2,s2,a1
    80001d7e:	7928                	ld	a0,112(a0)
    80001d80:	fffff097          	auipc	ra,0xfffff
    80001d84:	690080e7          	jalr	1680(ra) # 80001410 <uvmalloc>
    80001d88:	85aa                	mv	a1,a0
    80001d8a:	fd79                	bnez	a0,80001d68 <growproc+0x22>
      return -1;
    80001d8c:	557d                	li	a0,-1
    80001d8e:	bff9                	j	80001d6c <growproc+0x26>
    sz = uvmdealloc(p->pagetable, sz, sz + n);
    80001d90:	00b90633          	add	a2,s2,a1
    80001d94:	7928                	ld	a0,112(a0)
    80001d96:	fffff097          	auipc	ra,0xfffff
    80001d9a:	632080e7          	jalr	1586(ra) # 800013c8 <uvmdealloc>
    80001d9e:	85aa                	mv	a1,a0
    80001da0:	b7e1                	j	80001d68 <growproc+0x22>

0000000080001da2 <fork>:
{
    80001da2:	7139                	addi	sp,sp,-64
    80001da4:	fc06                	sd	ra,56(sp)
    80001da6:	f822                	sd	s0,48(sp)
    80001da8:	f426                	sd	s1,40(sp)
    80001daa:	f04a                	sd	s2,32(sp)
    80001dac:	ec4e                	sd	s3,24(sp)
    80001dae:	e852                	sd	s4,16(sp)
    80001db0:	e456                	sd	s5,8(sp)
    80001db2:	0080                	addi	s0,sp,64
  struct proc *p = myproc();
    80001db4:	00000097          	auipc	ra,0x0
    80001db8:	bf8080e7          	jalr	-1032(ra) # 800019ac <myproc>
    80001dbc:	8aaa                	mv	s5,a0
  if ((np = allocproc()) == 0)
    80001dbe:	00000097          	auipc	ra,0x0
    80001dc2:	e06080e7          	jalr	-506(ra) # 80001bc4 <allocproc>
    80001dc6:	10050c63          	beqz	a0,80001ede <fork+0x13c>
    80001dca:	8a2a                	mv	s4,a0
  if (uvmcopy(p->pagetable, np->pagetable, p->sz) < 0)
    80001dcc:	068ab603          	ld	a2,104(s5)
    80001dd0:	792c                	ld	a1,112(a0)
    80001dd2:	070ab503          	ld	a0,112(s5)
    80001dd6:	fffff097          	auipc	ra,0xfffff
    80001dda:	792080e7          	jalr	1938(ra) # 80001568 <uvmcopy>
    80001dde:	04054863          	bltz	a0,80001e2e <fork+0x8c>
  np->sz = p->sz;
    80001de2:	068ab783          	ld	a5,104(s5)
    80001de6:	06fa3423          	sd	a5,104(s4)
  *(np->trapframe) = *(p->trapframe);
    80001dea:	078ab683          	ld	a3,120(s5)
    80001dee:	87b6                	mv	a5,a3
    80001df0:	078a3703          	ld	a4,120(s4)
    80001df4:	12068693          	addi	a3,a3,288
    80001df8:	0007b803          	ld	a6,0(a5) # 1000 <_entry-0x7ffff000>
    80001dfc:	6788                	ld	a0,8(a5)
    80001dfe:	6b8c                	ld	a1,16(a5)
    80001e00:	6f90                	ld	a2,24(a5)
    80001e02:	01073023          	sd	a6,0(a4)
    80001e06:	e708                	sd	a0,8(a4)
    80001e08:	eb0c                	sd	a1,16(a4)
    80001e0a:	ef10                	sd	a2,24(a4)
    80001e0c:	02078793          	addi	a5,a5,32
    80001e10:	02070713          	addi	a4,a4,32
    80001e14:	fed792e3          	bne	a5,a3,80001df8 <fork+0x56>
  np->trapframe->a0 = 0;
    80001e18:	078a3783          	ld	a5,120(s4)
    80001e1c:	0607b823          	sd	zero,112(a5)
  for (i = 0; i < NOFILE; i++)
    80001e20:	0f0a8493          	addi	s1,s5,240
    80001e24:	0f0a0913          	addi	s2,s4,240
    80001e28:	170a8993          	addi	s3,s5,368
    80001e2c:	a00d                	j	80001e4e <fork+0xac>
    freeproc(np);
    80001e2e:	8552                	mv	a0,s4
    80001e30:	00000097          	auipc	ra,0x0
    80001e34:	d2e080e7          	jalr	-722(ra) # 80001b5e <freeproc>
    release(&np->lock);
    80001e38:	8552                	mv	a0,s4
    80001e3a:	fffff097          	auipc	ra,0xfffff
    80001e3e:	e50080e7          	jalr	-432(ra) # 80000c8a <release>
    return -1;
    80001e42:	597d                	li	s2,-1
    80001e44:	a059                	j	80001eca <fork+0x128>
  for (i = 0; i < NOFILE; i++)
    80001e46:	04a1                	addi	s1,s1,8
    80001e48:	0921                	addi	s2,s2,8
    80001e4a:	01348b63          	beq	s1,s3,80001e60 <fork+0xbe>
    if (p->ofile[i])
    80001e4e:	6088                	ld	a0,0(s1)
    80001e50:	d97d                	beqz	a0,80001e46 <fork+0xa4>
      np->ofile[i] = filedup(p->ofile[i]);
    80001e52:	00003097          	auipc	ra,0x3
    80001e56:	d7c080e7          	jalr	-644(ra) # 80004bce <filedup>
    80001e5a:	00a93023          	sd	a0,0(s2)
    80001e5e:	b7e5                	j	80001e46 <fork+0xa4>
  np->cwd = idup(p->cwd);
    80001e60:	170ab503          	ld	a0,368(s5)
    80001e64:	00002097          	auipc	ra,0x2
    80001e68:	eea080e7          	jalr	-278(ra) # 80003d4e <idup>
    80001e6c:	16aa3823          	sd	a0,368(s4)
  safestrcpy(np->name, p->name, sizeof(p->name));
    80001e70:	4641                	li	a2,16
    80001e72:	178a8593          	addi	a1,s5,376
    80001e76:	178a0513          	addi	a0,s4,376
    80001e7a:	fffff097          	auipc	ra,0xfffff
    80001e7e:	fa2080e7          	jalr	-94(ra) # 80000e1c <safestrcpy>
  pid = np->pid;
    80001e82:	030a2903          	lw	s2,48(s4)
  release(&np->lock);
    80001e86:	8552                	mv	a0,s4
    80001e88:	fffff097          	auipc	ra,0xfffff
    80001e8c:	e02080e7          	jalr	-510(ra) # 80000c8a <release>
  acquire(&wait_lock);
    80001e90:	0000f497          	auipc	s1,0xf
    80001e94:	cf848493          	addi	s1,s1,-776 # 80010b88 <wait_lock>
    80001e98:	8526                	mv	a0,s1
    80001e9a:	fffff097          	auipc	ra,0xfffff
    80001e9e:	d3c080e7          	jalr	-708(ra) # 80000bd6 <acquire>
  np->parent = p;
    80001ea2:	035a3c23          	sd	s5,56(s4)
  release(&wait_lock);
    80001ea6:	8526                	mv	a0,s1
    80001ea8:	fffff097          	auipc	ra,0xfffff
    80001eac:	de2080e7          	jalr	-542(ra) # 80000c8a <release>
  acquire(&np->lock);
    80001eb0:	8552                	mv	a0,s4
    80001eb2:	fffff097          	auipc	ra,0xfffff
    80001eb6:	d24080e7          	jalr	-732(ra) # 80000bd6 <acquire>
  np->state = RUNNABLE;
    80001eba:	478d                	li	a5,3
    80001ebc:	00fa2c23          	sw	a5,24(s4)
  release(&np->lock);
    80001ec0:	8552                	mv	a0,s4
    80001ec2:	fffff097          	auipc	ra,0xfffff
    80001ec6:	dc8080e7          	jalr	-568(ra) # 80000c8a <release>
}
    80001eca:	854a                	mv	a0,s2
    80001ecc:	70e2                	ld	ra,56(sp)
    80001ece:	7442                	ld	s0,48(sp)
    80001ed0:	74a2                	ld	s1,40(sp)
    80001ed2:	7902                	ld	s2,32(sp)
    80001ed4:	69e2                	ld	s3,24(sp)
    80001ed6:	6a42                	ld	s4,16(sp)
    80001ed8:	6aa2                	ld	s5,8(sp)
    80001eda:	6121                	addi	sp,sp,64
    80001edc:	8082                	ret
    return -1;
    80001ede:	597d                	li	s2,-1
    80001ee0:	b7ed                	j	80001eca <fork+0x128>

0000000080001ee2 <scheduler>:
{
    80001ee2:	7119                	addi	sp,sp,-128
    80001ee4:	fc86                	sd	ra,120(sp)
    80001ee6:	f8a2                	sd	s0,112(sp)
    80001ee8:	f4a6                	sd	s1,104(sp)
    80001eea:	f0ca                	sd	s2,96(sp)
    80001eec:	ecce                	sd	s3,88(sp)
    80001eee:	e8d2                	sd	s4,80(sp)
    80001ef0:	e4d6                	sd	s5,72(sp)
    80001ef2:	e0da                	sd	s6,64(sp)
    80001ef4:	fc5e                	sd	s7,56(sp)
    80001ef6:	f862                	sd	s8,48(sp)
    80001ef8:	f466                	sd	s9,40(sp)
    80001efa:	f06a                	sd	s10,32(sp)
    80001efc:	ec6e                	sd	s11,24(sp)
    80001efe:	0100                	addi	s0,sp,128
    80001f00:	8792                	mv	a5,tp
  int id = r_tp();
    80001f02:	2781                	sext.w	a5,a5
  c->proc = 0;
    80001f04:	00779693          	slli	a3,a5,0x7
    80001f08:	0000f717          	auipc	a4,0xf
    80001f0c:	c6870713          	addi	a4,a4,-920 # 80010b70 <pid_lock>
    80001f10:	9736                	add	a4,a4,a3
    80001f12:	02073823          	sd	zero,48(a4)
        swtch(&c->context, &temp->context);
    80001f16:	0000f717          	auipc	a4,0xf
    80001f1a:	c9270713          	addi	a4,a4,-878 # 80010ba8 <cpus+0x8>
    80001f1e:	9736                	add	a4,a4,a3
    80001f20:	f8e43423          	sd	a4,-120(s0)
    int flag = 0;
    80001f24:	4d01                	li	s10,0
    for (p = proc; p < &proc[NPROC]; p++)
    80001f26:	00016a97          	auipc	s5,0x16
    80001f2a:	87aa8a93          	addi	s5,s5,-1926 # 800177a0 <tickslock>
        c->proc = temp;
    80001f2e:	0000fd97          	auipc	s11,0xf
    80001f32:	c42d8d93          	addi	s11,s11,-958 # 80010b70 <pid_lock>
    80001f36:	9db6                	add	s11,s11,a3
    80001f38:	a0e1                	j	80002000 <scheduler+0x11e>
          if (p->in_time < temp->in_time)
    80001f3a:	ff44a703          	lw	a4,-12(s1)
    80001f3e:	194ba783          	lw	a5,404(s7) # fffffffffffff194 <end+0xffffffff7ffdc614>
    80001f42:	04f74263          	blt	a4,a5,80001f86 <scheduler+0xa4>
      release(&p->lock);
    80001f46:	8552                	mv	a0,s4
    80001f48:	fffff097          	auipc	ra,0xfffff
    80001f4c:	d42080e7          	jalr	-702(ra) # 80000c8a <release>
    for (p = proc; p < &proc[NPROC]; p++)
    80001f50:	0559f563          	bgeu	s3,s5,80001f9a <scheduler+0xb8>
    80001f54:	1a090913          	addi	s2,s2,416
    80001f58:	1a048493          	addi	s1,s1,416
    80001f5c:	8a4a                	mv	s4,s2
      acquire(&p->lock);
    80001f5e:	854a                	mv	a0,s2
    80001f60:	fffff097          	auipc	ra,0xfffff
    80001f64:	c76080e7          	jalr	-906(ra) # 80000bd6 <acquire>
      if (p->state == RUNNABLE)
    80001f68:	89a6                	mv	s3,s1
    80001f6a:	e784a783          	lw	a5,-392(s1)
    80001f6e:	fd679ce3          	bne	a5,s6,80001f46 <scheduler+0x64>
        if (temp == 0)
    80001f72:	000b8a63          	beqz	s7,80001f86 <scheduler+0xa4>
        else if (p->que_no == temp->que_no)
    80001f76:	ff84a703          	lw	a4,-8(s1)
    80001f7a:	198ba783          	lw	a5,408(s7)
    80001f7e:	faf70ee3          	beq	a4,a5,80001f3a <scheduler+0x58>
        else if (p->que_no < temp->que_no)
    80001f82:	fcf752e3          	bge	a4,a5,80001f46 <scheduler+0x64>
      release(&p->lock);
    80001f86:	8552                	mv	a0,s4
    80001f88:	fffff097          	auipc	ra,0xfffff
    80001f8c:	d02080e7          	jalr	-766(ra) # 80000c8a <release>
    for (p = proc; p < &proc[NPROC]; p++)
    80001f90:	0359f963          	bgeu	s3,s5,80001fc2 <scheduler+0xe0>
    80001f94:	8bd2                	mv	s7,s4
    80001f96:	8c66                	mv	s8,s9
    80001f98:	bf75                	j	80001f54 <scheduler+0x72>
    if (flag == 1)
    80001f9a:	039c0363          	beq	s8,s9,80001fc0 <scheduler+0xde>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80001f9e:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80001fa2:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80001fa6:	10079073          	csrw	sstatus,a5
    for (p = proc; p < &proc[NPROC]; p++)
    80001faa:	0000f917          	auipc	s2,0xf
    80001fae:	ff690913          	addi	s2,s2,-10 # 80010fa0 <proc>
    80001fb2:	0000f497          	auipc	s1,0xf
    80001fb6:	18e48493          	addi	s1,s1,398 # 80011140 <proc+0x1a0>
    int flag = 0;
    80001fba:	8c6a                	mv	s8,s10
    struct proc *temp = 0;
    80001fbc:	8bea                	mv	s7,s10
    80001fbe:	bf79                	j	80001f5c <scheduler+0x7a>
    80001fc0:	8a5e                	mv	s4,s7
      acquire(&temp->lock);
    80001fc2:	84d2                	mv	s1,s4
    80001fc4:	8552                	mv	a0,s4
    80001fc6:	fffff097          	auipc	ra,0xfffff
    80001fca:	c10080e7          	jalr	-1008(ra) # 80000bd6 <acquire>
      if (temp->state == RUNNABLE)
    80001fce:	018a2703          	lw	a4,24(s4)
    80001fd2:	478d                	li	a5,3
    80001fd4:	02f71163          	bne	a4,a5,80001ff6 <scheduler+0x114>
        temp->state = RUNNING;
    80001fd8:	4791                	li	a5,4
    80001fda:	00fa2c23          	sw	a5,24(s4)
        c->proc = temp;
    80001fde:	034db823          	sd	s4,48(s11)
        swtch(&c->context, &temp->context);
    80001fe2:	080a0593          	addi	a1,s4,128
    80001fe6:	f8843503          	ld	a0,-120(s0)
    80001fea:	00001097          	auipc	ra,0x1
    80001fee:	87a080e7          	jalr	-1926(ra) # 80002864 <swtch>
        c->proc = 0;
    80001ff2:	020db823          	sd	zero,48(s11)
      release(&temp->lock);
    80001ff6:	8526                	mv	a0,s1
    80001ff8:	fffff097          	auipc	ra,0xfffff
    80001ffc:	c92080e7          	jalr	-878(ra) # 80000c8a <release>
      if (p->state == RUNNABLE)
    80002000:	4b0d                	li	s6,3
    for (p = proc; p < &proc[NPROC]; p++)
    80002002:	4c85                	li	s9,1
    80002004:	bf69                	j	80001f9e <scheduler+0xbc>

0000000080002006 <sched>:
{
    80002006:	7179                	addi	sp,sp,-48
    80002008:	f406                	sd	ra,40(sp)
    8000200a:	f022                	sd	s0,32(sp)
    8000200c:	ec26                	sd	s1,24(sp)
    8000200e:	e84a                	sd	s2,16(sp)
    80002010:	e44e                	sd	s3,8(sp)
    80002012:	1800                	addi	s0,sp,48
  struct proc *p = myproc();
    80002014:	00000097          	auipc	ra,0x0
    80002018:	998080e7          	jalr	-1640(ra) # 800019ac <myproc>
    8000201c:	84aa                	mv	s1,a0
  if (!holding(&p->lock))
    8000201e:	fffff097          	auipc	ra,0xfffff
    80002022:	b3e080e7          	jalr	-1218(ra) # 80000b5c <holding>
    80002026:	c93d                	beqz	a0,8000209c <sched+0x96>
  asm volatile("mv %0, tp" : "=r" (x) );
    80002028:	8792                	mv	a5,tp
  if (mycpu()->noff != 1)
    8000202a:	2781                	sext.w	a5,a5
    8000202c:	079e                	slli	a5,a5,0x7
    8000202e:	0000f717          	auipc	a4,0xf
    80002032:	b4270713          	addi	a4,a4,-1214 # 80010b70 <pid_lock>
    80002036:	97ba                	add	a5,a5,a4
    80002038:	0a87a703          	lw	a4,168(a5)
    8000203c:	4785                	li	a5,1
    8000203e:	06f71763          	bne	a4,a5,800020ac <sched+0xa6>
  if (p->state == RUNNING)
    80002042:	4c98                	lw	a4,24(s1)
    80002044:	4791                	li	a5,4
    80002046:	06f70b63          	beq	a4,a5,800020bc <sched+0xb6>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    8000204a:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    8000204e:	8b89                	andi	a5,a5,2
  if (intr_get())
    80002050:	efb5                	bnez	a5,800020cc <sched+0xc6>
  asm volatile("mv %0, tp" : "=r" (x) );
    80002052:	8792                	mv	a5,tp
  intena = mycpu()->intena;
    80002054:	0000f917          	auipc	s2,0xf
    80002058:	b1c90913          	addi	s2,s2,-1252 # 80010b70 <pid_lock>
    8000205c:	2781                	sext.w	a5,a5
    8000205e:	079e                	slli	a5,a5,0x7
    80002060:	97ca                	add	a5,a5,s2
    80002062:	0ac7a983          	lw	s3,172(a5)
    80002066:	8792                	mv	a5,tp
  swtch(&p->context, &mycpu()->context);
    80002068:	2781                	sext.w	a5,a5
    8000206a:	079e                	slli	a5,a5,0x7
    8000206c:	0000f597          	auipc	a1,0xf
    80002070:	b3c58593          	addi	a1,a1,-1220 # 80010ba8 <cpus+0x8>
    80002074:	95be                	add	a1,a1,a5
    80002076:	08048513          	addi	a0,s1,128
    8000207a:	00000097          	auipc	ra,0x0
    8000207e:	7ea080e7          	jalr	2026(ra) # 80002864 <swtch>
    80002082:	8792                	mv	a5,tp
  mycpu()->intena = intena;
    80002084:	2781                	sext.w	a5,a5
    80002086:	079e                	slli	a5,a5,0x7
    80002088:	993e                	add	s2,s2,a5
    8000208a:	0b392623          	sw	s3,172(s2)
}
    8000208e:	70a2                	ld	ra,40(sp)
    80002090:	7402                	ld	s0,32(sp)
    80002092:	64e2                	ld	s1,24(sp)
    80002094:	6942                	ld	s2,16(sp)
    80002096:	69a2                	ld	s3,8(sp)
    80002098:	6145                	addi	sp,sp,48
    8000209a:	8082                	ret
    panic("sched p->lock");
    8000209c:	00006517          	auipc	a0,0x6
    800020a0:	17c50513          	addi	a0,a0,380 # 80008218 <digits+0x1d8>
    800020a4:	ffffe097          	auipc	ra,0xffffe
    800020a8:	49c080e7          	jalr	1180(ra) # 80000540 <panic>
    panic("sched locks");
    800020ac:	00006517          	auipc	a0,0x6
    800020b0:	17c50513          	addi	a0,a0,380 # 80008228 <digits+0x1e8>
    800020b4:	ffffe097          	auipc	ra,0xffffe
    800020b8:	48c080e7          	jalr	1164(ra) # 80000540 <panic>
    panic("sched running");
    800020bc:	00006517          	auipc	a0,0x6
    800020c0:	17c50513          	addi	a0,a0,380 # 80008238 <digits+0x1f8>
    800020c4:	ffffe097          	auipc	ra,0xffffe
    800020c8:	47c080e7          	jalr	1148(ra) # 80000540 <panic>
    panic("sched interruptible");
    800020cc:	00006517          	auipc	a0,0x6
    800020d0:	17c50513          	addi	a0,a0,380 # 80008248 <digits+0x208>
    800020d4:	ffffe097          	auipc	ra,0xffffe
    800020d8:	46c080e7          	jalr	1132(ra) # 80000540 <panic>

00000000800020dc <yield>:
{
    800020dc:	1101                	addi	sp,sp,-32
    800020de:	ec06                	sd	ra,24(sp)
    800020e0:	e822                	sd	s0,16(sp)
    800020e2:	e426                	sd	s1,8(sp)
    800020e4:	1000                	addi	s0,sp,32
  struct proc *p = myproc();
    800020e6:	00000097          	auipc	ra,0x0
    800020ea:	8c6080e7          	jalr	-1850(ra) # 800019ac <myproc>
    800020ee:	84aa                	mv	s1,a0
  acquire(&p->lock);
    800020f0:	fffff097          	auipc	ra,0xfffff
    800020f4:	ae6080e7          	jalr	-1306(ra) # 80000bd6 <acquire>
  p->state = RUNNABLE;
    800020f8:	478d                	li	a5,3
    800020fa:	cc9c                	sw	a5,24(s1)
  sched();
    800020fc:	00000097          	auipc	ra,0x0
    80002100:	f0a080e7          	jalr	-246(ra) # 80002006 <sched>
  release(&p->lock);
    80002104:	8526                	mv	a0,s1
    80002106:	fffff097          	auipc	ra,0xfffff
    8000210a:	b84080e7          	jalr	-1148(ra) # 80000c8a <release>
}
    8000210e:	60e2                	ld	ra,24(sp)
    80002110:	6442                	ld	s0,16(sp)
    80002112:	64a2                	ld	s1,8(sp)
    80002114:	6105                	addi	sp,sp,32
    80002116:	8082                	ret

0000000080002118 <sleep>:

// Atomically release lock and sleep on chan.
// Reacquires lock when awakened.
void sleep(void *chan, struct spinlock *lk)
{
    80002118:	7179                	addi	sp,sp,-48
    8000211a:	f406                	sd	ra,40(sp)
    8000211c:	f022                	sd	s0,32(sp)
    8000211e:	ec26                	sd	s1,24(sp)
    80002120:	e84a                	sd	s2,16(sp)
    80002122:	e44e                	sd	s3,8(sp)
    80002124:	1800                	addi	s0,sp,48
    80002126:	89aa                	mv	s3,a0
    80002128:	892e                	mv	s2,a1
  struct proc *p = myproc();
    8000212a:	00000097          	auipc	ra,0x0
    8000212e:	882080e7          	jalr	-1918(ra) # 800019ac <myproc>
    80002132:	84aa                	mv	s1,a0
  // Once we hold p->lock, we can be
  // guaranteed that we won't miss any wakeup
  // (wakeup locks p->lock),
  // so it's okay to release lk.

  acquire(&p->lock); // DOC: sleeplock1
    80002134:	fffff097          	auipc	ra,0xfffff
    80002138:	aa2080e7          	jalr	-1374(ra) # 80000bd6 <acquire>
  release(lk);
    8000213c:	854a                	mv	a0,s2
    8000213e:	fffff097          	auipc	ra,0xfffff
    80002142:	b4c080e7          	jalr	-1204(ra) # 80000c8a <release>

  // Go to sleep.
  p->chan = chan;
    80002146:	0334b023          	sd	s3,32(s1)
  p->state = SLEEPING;
    8000214a:	4789                	li	a5,2
    8000214c:	cc9c                	sw	a5,24(s1)

  sched();
    8000214e:	00000097          	auipc	ra,0x0
    80002152:	eb8080e7          	jalr	-328(ra) # 80002006 <sched>

  // Tidy up.
  p->chan = 0;
    80002156:	0204b023          	sd	zero,32(s1)

  // Reacquire original lock.
  release(&p->lock);
    8000215a:	8526                	mv	a0,s1
    8000215c:	fffff097          	auipc	ra,0xfffff
    80002160:	b2e080e7          	jalr	-1234(ra) # 80000c8a <release>
  acquire(lk);
    80002164:	854a                	mv	a0,s2
    80002166:	fffff097          	auipc	ra,0xfffff
    8000216a:	a70080e7          	jalr	-1424(ra) # 80000bd6 <acquire>
}
    8000216e:	70a2                	ld	ra,40(sp)
    80002170:	7402                	ld	s0,32(sp)
    80002172:	64e2                	ld	s1,24(sp)
    80002174:	6942                	ld	s2,16(sp)
    80002176:	69a2                	ld	s3,8(sp)
    80002178:	6145                	addi	sp,sp,48
    8000217a:	8082                	ret

000000008000217c <wakeup>:

// Wake up all processes sleeping on chan.
// Must be called without any p->lock.
void wakeup(void *chan)
{
    8000217c:	7139                	addi	sp,sp,-64
    8000217e:	fc06                	sd	ra,56(sp)
    80002180:	f822                	sd	s0,48(sp)
    80002182:	f426                	sd	s1,40(sp)
    80002184:	f04a                	sd	s2,32(sp)
    80002186:	ec4e                	sd	s3,24(sp)
    80002188:	e852                	sd	s4,16(sp)
    8000218a:	e456                	sd	s5,8(sp)
    8000218c:	e05a                	sd	s6,0(sp)
    8000218e:	0080                	addi	s0,sp,64
    80002190:	8a2a                	mv	s4,a0
  struct proc *p;

  for (p = proc; p < &proc[NPROC]; p++)
    80002192:	0000f497          	auipc	s1,0xf
    80002196:	e0e48493          	addi	s1,s1,-498 # 80010fa0 <proc>
  {
    if (p != myproc())
    {
      acquire(&p->lock);
      if (p->state == SLEEPING && p->chan == chan)
    8000219a:	4989                	li	s3,2
      {
        p->state = RUNNABLE;
    8000219c:	4b0d                	li	s6,3
        p->in_time = ticks;
    8000219e:	00006a97          	auipc	s5,0x6
    800021a2:	762a8a93          	addi	s5,s5,1890 # 80008900 <ticks>
  for (p = proc; p < &proc[NPROC]; p++)
    800021a6:	00015917          	auipc	s2,0x15
    800021aa:	5fa90913          	addi	s2,s2,1530 # 800177a0 <tickslock>
    800021ae:	a811                	j	800021c2 <wakeup+0x46>
      }
      release(&p->lock);
    800021b0:	8526                	mv	a0,s1
    800021b2:	fffff097          	auipc	ra,0xfffff
    800021b6:	ad8080e7          	jalr	-1320(ra) # 80000c8a <release>
  for (p = proc; p < &proc[NPROC]; p++)
    800021ba:	1a048493          	addi	s1,s1,416
    800021be:	03248a63          	beq	s1,s2,800021f2 <wakeup+0x76>
    if (p != myproc())
    800021c2:	fffff097          	auipc	ra,0xfffff
    800021c6:	7ea080e7          	jalr	2026(ra) # 800019ac <myproc>
    800021ca:	fea488e3          	beq	s1,a0,800021ba <wakeup+0x3e>
      acquire(&p->lock);
    800021ce:	8526                	mv	a0,s1
    800021d0:	fffff097          	auipc	ra,0xfffff
    800021d4:	a06080e7          	jalr	-1530(ra) # 80000bd6 <acquire>
      if (p->state == SLEEPING && p->chan == chan)
    800021d8:	4c9c                	lw	a5,24(s1)
    800021da:	fd379be3          	bne	a5,s3,800021b0 <wakeup+0x34>
    800021de:	709c                	ld	a5,32(s1)
    800021e0:	fd4798e3          	bne	a5,s4,800021b0 <wakeup+0x34>
        p->state = RUNNABLE;
    800021e4:	0164ac23          	sw	s6,24(s1)
        p->in_time = ticks;
    800021e8:	000aa783          	lw	a5,0(s5)
    800021ec:	18f4aa23          	sw	a5,404(s1)
    800021f0:	b7c1                	j	800021b0 <wakeup+0x34>
    }
  }
}
    800021f2:	70e2                	ld	ra,56(sp)
    800021f4:	7442                	ld	s0,48(sp)
    800021f6:	74a2                	ld	s1,40(sp)
    800021f8:	7902                	ld	s2,32(sp)
    800021fa:	69e2                	ld	s3,24(sp)
    800021fc:	6a42                	ld	s4,16(sp)
    800021fe:	6aa2                	ld	s5,8(sp)
    80002200:	6b02                	ld	s6,0(sp)
    80002202:	6121                	addi	sp,sp,64
    80002204:	8082                	ret

0000000080002206 <reparent>:
{
    80002206:	7179                	addi	sp,sp,-48
    80002208:	f406                	sd	ra,40(sp)
    8000220a:	f022                	sd	s0,32(sp)
    8000220c:	ec26                	sd	s1,24(sp)
    8000220e:	e84a                	sd	s2,16(sp)
    80002210:	e44e                	sd	s3,8(sp)
    80002212:	e052                	sd	s4,0(sp)
    80002214:	1800                	addi	s0,sp,48
    80002216:	892a                	mv	s2,a0
  for (pp = proc; pp < &proc[NPROC]; pp++)
    80002218:	0000f497          	auipc	s1,0xf
    8000221c:	d8848493          	addi	s1,s1,-632 # 80010fa0 <proc>
      pp->parent = initproc;
    80002220:	00006a17          	auipc	s4,0x6
    80002224:	6d8a0a13          	addi	s4,s4,1752 # 800088f8 <initproc>
  for (pp = proc; pp < &proc[NPROC]; pp++)
    80002228:	00015997          	auipc	s3,0x15
    8000222c:	57898993          	addi	s3,s3,1400 # 800177a0 <tickslock>
    80002230:	a029                	j	8000223a <reparent+0x34>
    80002232:	1a048493          	addi	s1,s1,416
    80002236:	01348d63          	beq	s1,s3,80002250 <reparent+0x4a>
    if (pp->parent == p)
    8000223a:	7c9c                	ld	a5,56(s1)
    8000223c:	ff279be3          	bne	a5,s2,80002232 <reparent+0x2c>
      pp->parent = initproc;
    80002240:	000a3503          	ld	a0,0(s4)
    80002244:	fc88                	sd	a0,56(s1)
      wakeup(initproc);
    80002246:	00000097          	auipc	ra,0x0
    8000224a:	f36080e7          	jalr	-202(ra) # 8000217c <wakeup>
    8000224e:	b7d5                	j	80002232 <reparent+0x2c>
}
    80002250:	70a2                	ld	ra,40(sp)
    80002252:	7402                	ld	s0,32(sp)
    80002254:	64e2                	ld	s1,24(sp)
    80002256:	6942                	ld	s2,16(sp)
    80002258:	69a2                	ld	s3,8(sp)
    8000225a:	6a02                	ld	s4,0(sp)
    8000225c:	6145                	addi	sp,sp,48
    8000225e:	8082                	ret

0000000080002260 <exit>:
{
    80002260:	7179                	addi	sp,sp,-48
    80002262:	f406                	sd	ra,40(sp)
    80002264:	f022                	sd	s0,32(sp)
    80002266:	ec26                	sd	s1,24(sp)
    80002268:	e84a                	sd	s2,16(sp)
    8000226a:	e44e                	sd	s3,8(sp)
    8000226c:	e052                	sd	s4,0(sp)
    8000226e:	1800                	addi	s0,sp,48
    80002270:	8a2a                	mv	s4,a0
  struct proc *p = myproc();
    80002272:	fffff097          	auipc	ra,0xfffff
    80002276:	73a080e7          	jalr	1850(ra) # 800019ac <myproc>
    8000227a:	89aa                	mv	s3,a0
  if (p == initproc)
    8000227c:	00006797          	auipc	a5,0x6
    80002280:	67c7b783          	ld	a5,1660(a5) # 800088f8 <initproc>
    80002284:	0f050493          	addi	s1,a0,240
    80002288:	17050913          	addi	s2,a0,368
    8000228c:	02a79363          	bne	a5,a0,800022b2 <exit+0x52>
    panic("init2 exiting");
    80002290:	00006517          	auipc	a0,0x6
    80002294:	fd050513          	addi	a0,a0,-48 # 80008260 <digits+0x220>
    80002298:	ffffe097          	auipc	ra,0xffffe
    8000229c:	2a8080e7          	jalr	680(ra) # 80000540 <panic>
      fileclose(f);
    800022a0:	00003097          	auipc	ra,0x3
    800022a4:	980080e7          	jalr	-1664(ra) # 80004c20 <fileclose>
      p->ofile[fd] = 0;
    800022a8:	0004b023          	sd	zero,0(s1)
  for (int fd = 0; fd < NOFILE; fd++)
    800022ac:	04a1                	addi	s1,s1,8
    800022ae:	01248563          	beq	s1,s2,800022b8 <exit+0x58>
    if (p->ofile[fd])
    800022b2:	6088                	ld	a0,0(s1)
    800022b4:	f575                	bnez	a0,800022a0 <exit+0x40>
    800022b6:	bfdd                	j	800022ac <exit+0x4c>
  begin_op();
    800022b8:	00002097          	auipc	ra,0x2
    800022bc:	4a0080e7          	jalr	1184(ra) # 80004758 <begin_op>
  iput(p->cwd);
    800022c0:	1709b503          	ld	a0,368(s3)
    800022c4:	00002097          	auipc	ra,0x2
    800022c8:	c82080e7          	jalr	-894(ra) # 80003f46 <iput>
  end_op();
    800022cc:	00002097          	auipc	ra,0x2
    800022d0:	50a080e7          	jalr	1290(ra) # 800047d6 <end_op>
  p->cwd = 0;
    800022d4:	1609b823          	sd	zero,368(s3)
  acquire(&wait_lock);
    800022d8:	0000f497          	auipc	s1,0xf
    800022dc:	8b048493          	addi	s1,s1,-1872 # 80010b88 <wait_lock>
    800022e0:	8526                	mv	a0,s1
    800022e2:	fffff097          	auipc	ra,0xfffff
    800022e6:	8f4080e7          	jalr	-1804(ra) # 80000bd6 <acquire>
  reparent(p);
    800022ea:	854e                	mv	a0,s3
    800022ec:	00000097          	auipc	ra,0x0
    800022f0:	f1a080e7          	jalr	-230(ra) # 80002206 <reparent>
  wakeup(p->parent);
    800022f4:	0389b503          	ld	a0,56(s3)
    800022f8:	00000097          	auipc	ra,0x0
    800022fc:	e84080e7          	jalr	-380(ra) # 8000217c <wakeup>
  acquire(&p->lock);
    80002300:	854e                	mv	a0,s3
    80002302:	fffff097          	auipc	ra,0xfffff
    80002306:	8d4080e7          	jalr	-1836(ra) # 80000bd6 <acquire>
  p->xstate = status;
    8000230a:	0349a623          	sw	s4,44(s3)
  p->state = ZOMBIE;
    8000230e:	4795                	li	a5,5
    80002310:	00f9ac23          	sw	a5,24(s3)
  p->etime = ticks;
    80002314:	00006797          	auipc	a5,0x6
    80002318:	5ec7a783          	lw	a5,1516(a5) # 80008900 <ticks>
    8000231c:	18f9a823          	sw	a5,400(s3)
  release(&wait_lock);
    80002320:	8526                	mv	a0,s1
    80002322:	fffff097          	auipc	ra,0xfffff
    80002326:	968080e7          	jalr	-1688(ra) # 80000c8a <release>
  sched();
    8000232a:	00000097          	auipc	ra,0x0
    8000232e:	cdc080e7          	jalr	-804(ra) # 80002006 <sched>
  panic("zombie exit");
    80002332:	00006517          	auipc	a0,0x6
    80002336:	f3e50513          	addi	a0,a0,-194 # 80008270 <digits+0x230>
    8000233a:	ffffe097          	auipc	ra,0xffffe
    8000233e:	206080e7          	jalr	518(ra) # 80000540 <panic>

0000000080002342 <kill>:

// Kill the process with the given pid.
// The victim won't exit until it tries to return
// to user space (see usertrap() in trap.c).
int kill(int pid)
{
    80002342:	7179                	addi	sp,sp,-48
    80002344:	f406                	sd	ra,40(sp)
    80002346:	f022                	sd	s0,32(sp)
    80002348:	ec26                	sd	s1,24(sp)
    8000234a:	e84a                	sd	s2,16(sp)
    8000234c:	e44e                	sd	s3,8(sp)
    8000234e:	1800                	addi	s0,sp,48
    80002350:	892a                	mv	s2,a0
  struct proc *p;

  for (p = proc; p < &proc[NPROC]; p++)
    80002352:	0000f497          	auipc	s1,0xf
    80002356:	c4e48493          	addi	s1,s1,-946 # 80010fa0 <proc>
    8000235a:	00015997          	auipc	s3,0x15
    8000235e:	44698993          	addi	s3,s3,1094 # 800177a0 <tickslock>
  {
    acquire(&p->lock);
    80002362:	8526                	mv	a0,s1
    80002364:	fffff097          	auipc	ra,0xfffff
    80002368:	872080e7          	jalr	-1934(ra) # 80000bd6 <acquire>
    if (p->pid == pid)
    8000236c:	589c                	lw	a5,48(s1)
    8000236e:	01278d63          	beq	a5,s2,80002388 <kill+0x46>
        p->in_time = ticks;
      }
      release(&p->lock);
      return 0;
    }
    release(&p->lock);
    80002372:	8526                	mv	a0,s1
    80002374:	fffff097          	auipc	ra,0xfffff
    80002378:	916080e7          	jalr	-1770(ra) # 80000c8a <release>
  for (p = proc; p < &proc[NPROC]; p++)
    8000237c:	1a048493          	addi	s1,s1,416
    80002380:	ff3491e3          	bne	s1,s3,80002362 <kill+0x20>
  }
  return -1;
    80002384:	557d                	li	a0,-1
    80002386:	a829                	j	800023a0 <kill+0x5e>
      p->killed = 1;
    80002388:	4785                	li	a5,1
    8000238a:	d49c                	sw	a5,40(s1)
      if (p->state == SLEEPING)
    8000238c:	4c98                	lw	a4,24(s1)
    8000238e:	4789                	li	a5,2
    80002390:	00f70f63          	beq	a4,a5,800023ae <kill+0x6c>
      release(&p->lock);
    80002394:	8526                	mv	a0,s1
    80002396:	fffff097          	auipc	ra,0xfffff
    8000239a:	8f4080e7          	jalr	-1804(ra) # 80000c8a <release>
      return 0;
    8000239e:	4501                	li	a0,0
}
    800023a0:	70a2                	ld	ra,40(sp)
    800023a2:	7402                	ld	s0,32(sp)
    800023a4:	64e2                	ld	s1,24(sp)
    800023a6:	6942                	ld	s2,16(sp)
    800023a8:	69a2                	ld	s3,8(sp)
    800023aa:	6145                	addi	sp,sp,48
    800023ac:	8082                	ret
        p->state = RUNNABLE;
    800023ae:	478d                	li	a5,3
    800023b0:	cc9c                	sw	a5,24(s1)
        p->in_time = ticks;
    800023b2:	00006797          	auipc	a5,0x6
    800023b6:	54e7a783          	lw	a5,1358(a5) # 80008900 <ticks>
    800023ba:	18f4aa23          	sw	a5,404(s1)
    800023be:	bfd9                	j	80002394 <kill+0x52>

00000000800023c0 <setkilled>:

void setkilled(struct proc *p)
{
    800023c0:	1101                	addi	sp,sp,-32
    800023c2:	ec06                	sd	ra,24(sp)
    800023c4:	e822                	sd	s0,16(sp)
    800023c6:	e426                	sd	s1,8(sp)
    800023c8:	1000                	addi	s0,sp,32
    800023ca:	84aa                	mv	s1,a0
  acquire(&p->lock);
    800023cc:	fffff097          	auipc	ra,0xfffff
    800023d0:	80a080e7          	jalr	-2038(ra) # 80000bd6 <acquire>
  p->killed = 1;
    800023d4:	4785                	li	a5,1
    800023d6:	d49c                	sw	a5,40(s1)
  release(&p->lock);
    800023d8:	8526                	mv	a0,s1
    800023da:	fffff097          	auipc	ra,0xfffff
    800023de:	8b0080e7          	jalr	-1872(ra) # 80000c8a <release>
}
    800023e2:	60e2                	ld	ra,24(sp)
    800023e4:	6442                	ld	s0,16(sp)
    800023e6:	64a2                	ld	s1,8(sp)
    800023e8:	6105                	addi	sp,sp,32
    800023ea:	8082                	ret

00000000800023ec <killed>:

int killed(struct proc *p)
{
    800023ec:	1101                	addi	sp,sp,-32
    800023ee:	ec06                	sd	ra,24(sp)
    800023f0:	e822                	sd	s0,16(sp)
    800023f2:	e426                	sd	s1,8(sp)
    800023f4:	e04a                	sd	s2,0(sp)
    800023f6:	1000                	addi	s0,sp,32
    800023f8:	84aa                	mv	s1,a0
  int k;

  acquire(&p->lock);
    800023fa:	ffffe097          	auipc	ra,0xffffe
    800023fe:	7dc080e7          	jalr	2012(ra) # 80000bd6 <acquire>
  k = p->killed;
    80002402:	0284a903          	lw	s2,40(s1)
  release(&p->lock);
    80002406:	8526                	mv	a0,s1
    80002408:	fffff097          	auipc	ra,0xfffff
    8000240c:	882080e7          	jalr	-1918(ra) # 80000c8a <release>
  return k;
}
    80002410:	854a                	mv	a0,s2
    80002412:	60e2                	ld	ra,24(sp)
    80002414:	6442                	ld	s0,16(sp)
    80002416:	64a2                	ld	s1,8(sp)
    80002418:	6902                	ld	s2,0(sp)
    8000241a:	6105                	addi	sp,sp,32
    8000241c:	8082                	ret

000000008000241e <wait>:
{
    8000241e:	715d                	addi	sp,sp,-80
    80002420:	e486                	sd	ra,72(sp)
    80002422:	e0a2                	sd	s0,64(sp)
    80002424:	fc26                	sd	s1,56(sp)
    80002426:	f84a                	sd	s2,48(sp)
    80002428:	f44e                	sd	s3,40(sp)
    8000242a:	f052                	sd	s4,32(sp)
    8000242c:	ec56                	sd	s5,24(sp)
    8000242e:	e85a                	sd	s6,16(sp)
    80002430:	e45e                	sd	s7,8(sp)
    80002432:	e062                	sd	s8,0(sp)
    80002434:	0880                	addi	s0,sp,80
    80002436:	8b2a                	mv	s6,a0
  struct proc *p = myproc();
    80002438:	fffff097          	auipc	ra,0xfffff
    8000243c:	574080e7          	jalr	1396(ra) # 800019ac <myproc>
    80002440:	892a                	mv	s2,a0
  acquire(&wait_lock);
    80002442:	0000e517          	auipc	a0,0xe
    80002446:	74650513          	addi	a0,a0,1862 # 80010b88 <wait_lock>
    8000244a:	ffffe097          	auipc	ra,0xffffe
    8000244e:	78c080e7          	jalr	1932(ra) # 80000bd6 <acquire>
    havekids = 0;
    80002452:	4b81                	li	s7,0
        if (pp->state == ZOMBIE)
    80002454:	4a15                	li	s4,5
        havekids = 1;
    80002456:	4a85                	li	s5,1
    for (pp = proc; pp < &proc[NPROC]; pp++)
    80002458:	00015997          	auipc	s3,0x15
    8000245c:	34898993          	addi	s3,s3,840 # 800177a0 <tickslock>
    sleep(p, &wait_lock); // DOC: wait-sleep
    80002460:	0000ec17          	auipc	s8,0xe
    80002464:	728c0c13          	addi	s8,s8,1832 # 80010b88 <wait_lock>
    havekids = 0;
    80002468:	875e                	mv	a4,s7
    for (pp = proc; pp < &proc[NPROC]; pp++)
    8000246a:	0000f497          	auipc	s1,0xf
    8000246e:	b3648493          	addi	s1,s1,-1226 # 80010fa0 <proc>
    80002472:	a0bd                	j	800024e0 <wait+0xc2>
          pid = pp->pid;
    80002474:	0304a983          	lw	s3,48(s1)
          if (addr != 0 && copyout(p->pagetable, addr, (char *)&pp->xstate,
    80002478:	000b0e63          	beqz	s6,80002494 <wait+0x76>
    8000247c:	4691                	li	a3,4
    8000247e:	02c48613          	addi	a2,s1,44
    80002482:	85da                	mv	a1,s6
    80002484:	07093503          	ld	a0,112(s2)
    80002488:	fffff097          	auipc	ra,0xfffff
    8000248c:	1e4080e7          	jalr	484(ra) # 8000166c <copyout>
    80002490:	02054563          	bltz	a0,800024ba <wait+0x9c>
          freeproc(pp);
    80002494:	8526                	mv	a0,s1
    80002496:	fffff097          	auipc	ra,0xfffff
    8000249a:	6c8080e7          	jalr	1736(ra) # 80001b5e <freeproc>
          release(&pp->lock);
    8000249e:	8526                	mv	a0,s1
    800024a0:	ffffe097          	auipc	ra,0xffffe
    800024a4:	7ea080e7          	jalr	2026(ra) # 80000c8a <release>
          release(&wait_lock);
    800024a8:	0000e517          	auipc	a0,0xe
    800024ac:	6e050513          	addi	a0,a0,1760 # 80010b88 <wait_lock>
    800024b0:	ffffe097          	auipc	ra,0xffffe
    800024b4:	7da080e7          	jalr	2010(ra) # 80000c8a <release>
          return pid;
    800024b8:	a0b5                	j	80002524 <wait+0x106>
            release(&pp->lock);
    800024ba:	8526                	mv	a0,s1
    800024bc:	ffffe097          	auipc	ra,0xffffe
    800024c0:	7ce080e7          	jalr	1998(ra) # 80000c8a <release>
            release(&wait_lock);
    800024c4:	0000e517          	auipc	a0,0xe
    800024c8:	6c450513          	addi	a0,a0,1732 # 80010b88 <wait_lock>
    800024cc:	ffffe097          	auipc	ra,0xffffe
    800024d0:	7be080e7          	jalr	1982(ra) # 80000c8a <release>
            return -1;
    800024d4:	59fd                	li	s3,-1
    800024d6:	a0b9                	j	80002524 <wait+0x106>
    for (pp = proc; pp < &proc[NPROC]; pp++)
    800024d8:	1a048493          	addi	s1,s1,416
    800024dc:	03348463          	beq	s1,s3,80002504 <wait+0xe6>
      if (pp->parent == p)
    800024e0:	7c9c                	ld	a5,56(s1)
    800024e2:	ff279be3          	bne	a5,s2,800024d8 <wait+0xba>
        acquire(&pp->lock);
    800024e6:	8526                	mv	a0,s1
    800024e8:	ffffe097          	auipc	ra,0xffffe
    800024ec:	6ee080e7          	jalr	1774(ra) # 80000bd6 <acquire>
        if (pp->state == ZOMBIE)
    800024f0:	4c9c                	lw	a5,24(s1)
    800024f2:	f94781e3          	beq	a5,s4,80002474 <wait+0x56>
        release(&pp->lock);
    800024f6:	8526                	mv	a0,s1
    800024f8:	ffffe097          	auipc	ra,0xffffe
    800024fc:	792080e7          	jalr	1938(ra) # 80000c8a <release>
        havekids = 1;
    80002500:	8756                	mv	a4,s5
    80002502:	bfd9                	j	800024d8 <wait+0xba>
    if (!havekids || killed(p))
    80002504:	c719                	beqz	a4,80002512 <wait+0xf4>
    80002506:	854a                	mv	a0,s2
    80002508:	00000097          	auipc	ra,0x0
    8000250c:	ee4080e7          	jalr	-284(ra) # 800023ec <killed>
    80002510:	c51d                	beqz	a0,8000253e <wait+0x120>
      release(&wait_lock);
    80002512:	0000e517          	auipc	a0,0xe
    80002516:	67650513          	addi	a0,a0,1654 # 80010b88 <wait_lock>
    8000251a:	ffffe097          	auipc	ra,0xffffe
    8000251e:	770080e7          	jalr	1904(ra) # 80000c8a <release>
      return -1;
    80002522:	59fd                	li	s3,-1
}
    80002524:	854e                	mv	a0,s3
    80002526:	60a6                	ld	ra,72(sp)
    80002528:	6406                	ld	s0,64(sp)
    8000252a:	74e2                	ld	s1,56(sp)
    8000252c:	7942                	ld	s2,48(sp)
    8000252e:	79a2                	ld	s3,40(sp)
    80002530:	7a02                	ld	s4,32(sp)
    80002532:	6ae2                	ld	s5,24(sp)
    80002534:	6b42                	ld	s6,16(sp)
    80002536:	6ba2                	ld	s7,8(sp)
    80002538:	6c02                	ld	s8,0(sp)
    8000253a:	6161                	addi	sp,sp,80
    8000253c:	8082                	ret
    sleep(p, &wait_lock); // DOC: wait-sleep
    8000253e:	85e2                	mv	a1,s8
    80002540:	854a                	mv	a0,s2
    80002542:	00000097          	auipc	ra,0x0
    80002546:	bd6080e7          	jalr	-1066(ra) # 80002118 <sleep>
    havekids = 0;
    8000254a:	bf39                	j	80002468 <wait+0x4a>

000000008000254c <either_copyout>:

// Copy to either a user address, or kernel address,
// depending on usr_dst.
// Returns 0 on success, -1 on error.
int either_copyout(int user_dst, uint64 dst, void *src, uint64 len)
{
    8000254c:	7179                	addi	sp,sp,-48
    8000254e:	f406                	sd	ra,40(sp)
    80002550:	f022                	sd	s0,32(sp)
    80002552:	ec26                	sd	s1,24(sp)
    80002554:	e84a                	sd	s2,16(sp)
    80002556:	e44e                	sd	s3,8(sp)
    80002558:	e052                	sd	s4,0(sp)
    8000255a:	1800                	addi	s0,sp,48
    8000255c:	84aa                	mv	s1,a0
    8000255e:	892e                	mv	s2,a1
    80002560:	89b2                	mv	s3,a2
    80002562:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    80002564:	fffff097          	auipc	ra,0xfffff
    80002568:	448080e7          	jalr	1096(ra) # 800019ac <myproc>
  if (user_dst)
    8000256c:	c08d                	beqz	s1,8000258e <either_copyout+0x42>
  {
    return copyout(p->pagetable, dst, src, len);
    8000256e:	86d2                	mv	a3,s4
    80002570:	864e                	mv	a2,s3
    80002572:	85ca                	mv	a1,s2
    80002574:	7928                	ld	a0,112(a0)
    80002576:	fffff097          	auipc	ra,0xfffff
    8000257a:	0f6080e7          	jalr	246(ra) # 8000166c <copyout>
  else
  {
    memmove((char *)dst, src, len);
    return 0;
  }
}
    8000257e:	70a2                	ld	ra,40(sp)
    80002580:	7402                	ld	s0,32(sp)
    80002582:	64e2                	ld	s1,24(sp)
    80002584:	6942                	ld	s2,16(sp)
    80002586:	69a2                	ld	s3,8(sp)
    80002588:	6a02                	ld	s4,0(sp)
    8000258a:	6145                	addi	sp,sp,48
    8000258c:	8082                	ret
    memmove((char *)dst, src, len);
    8000258e:	000a061b          	sext.w	a2,s4
    80002592:	85ce                	mv	a1,s3
    80002594:	854a                	mv	a0,s2
    80002596:	ffffe097          	auipc	ra,0xffffe
    8000259a:	798080e7          	jalr	1944(ra) # 80000d2e <memmove>
    return 0;
    8000259e:	8526                	mv	a0,s1
    800025a0:	bff9                	j	8000257e <either_copyout+0x32>

00000000800025a2 <either_copyin>:

// Copy from either a user address, or kernel address,
// depending on usr_src.
// Returns 0 on success, -1 on error.
int either_copyin(void *dst, int user_src, uint64 src, uint64 len)
{
    800025a2:	7179                	addi	sp,sp,-48
    800025a4:	f406                	sd	ra,40(sp)
    800025a6:	f022                	sd	s0,32(sp)
    800025a8:	ec26                	sd	s1,24(sp)
    800025aa:	e84a                	sd	s2,16(sp)
    800025ac:	e44e                	sd	s3,8(sp)
    800025ae:	e052                	sd	s4,0(sp)
    800025b0:	1800                	addi	s0,sp,48
    800025b2:	892a                	mv	s2,a0
    800025b4:	84ae                	mv	s1,a1
    800025b6:	89b2                	mv	s3,a2
    800025b8:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    800025ba:	fffff097          	auipc	ra,0xfffff
    800025be:	3f2080e7          	jalr	1010(ra) # 800019ac <myproc>
  if (user_src)
    800025c2:	c08d                	beqz	s1,800025e4 <either_copyin+0x42>
  {
    return copyin(p->pagetable, dst, src, len);
    800025c4:	86d2                	mv	a3,s4
    800025c6:	864e                	mv	a2,s3
    800025c8:	85ca                	mv	a1,s2
    800025ca:	7928                	ld	a0,112(a0)
    800025cc:	fffff097          	auipc	ra,0xfffff
    800025d0:	12c080e7          	jalr	300(ra) # 800016f8 <copyin>
  else
  {
    memmove(dst, (char *)src, len);
    return 0;
  }
}
    800025d4:	70a2                	ld	ra,40(sp)
    800025d6:	7402                	ld	s0,32(sp)
    800025d8:	64e2                	ld	s1,24(sp)
    800025da:	6942                	ld	s2,16(sp)
    800025dc:	69a2                	ld	s3,8(sp)
    800025de:	6a02                	ld	s4,0(sp)
    800025e0:	6145                	addi	sp,sp,48
    800025e2:	8082                	ret
    memmove(dst, (char *)src, len);
    800025e4:	000a061b          	sext.w	a2,s4
    800025e8:	85ce                	mv	a1,s3
    800025ea:	854a                	mv	a0,s2
    800025ec:	ffffe097          	auipc	ra,0xffffe
    800025f0:	742080e7          	jalr	1858(ra) # 80000d2e <memmove>
    return 0;
    800025f4:	8526                	mv	a0,s1
    800025f6:	bff9                	j	800025d4 <either_copyin+0x32>

00000000800025f8 <procdump>:

// Print a process listing to console.  For debugging.
// Runs when user types ^P on console.
// No lock to avoid wedging a stuck machine further.
void procdump(void)
{
    800025f8:	715d                	addi	sp,sp,-80
    800025fa:	e486                	sd	ra,72(sp)
    800025fc:	e0a2                	sd	s0,64(sp)
    800025fe:	fc26                	sd	s1,56(sp)
    80002600:	f84a                	sd	s2,48(sp)
    80002602:	f44e                	sd	s3,40(sp)
    80002604:	f052                	sd	s4,32(sp)
    80002606:	ec56                	sd	s5,24(sp)
    80002608:	e85a                	sd	s6,16(sp)
    8000260a:	e45e                	sd	s7,8(sp)
    8000260c:	e062                	sd	s8,0(sp)
    8000260e:	0880                	addi	s0,sp,80
      [RUNNING] "run   ",
      [ZOMBIE] "zombie"};
  struct proc *p;
  char *state;

  printf("\n");
    80002610:	00006517          	auipc	a0,0x6
    80002614:	ab850513          	addi	a0,a0,-1352 # 800080c8 <digits+0x88>
    80002618:	ffffe097          	auipc	ra,0xffffe
    8000261c:	f72080e7          	jalr	-142(ra) # 8000058a <printf>
  for (p = proc; p < &proc[NPROC]; p++)
    80002620:	0000f497          	auipc	s1,0xf
    80002624:	af848493          	addi	s1,s1,-1288 # 80011118 <proc+0x178>
    80002628:	00015917          	auipc	s2,0x15
    8000262c:	2f090913          	addi	s2,s2,752 # 80017918 <bcache+0x160>
  {
    if (p->state == UNUSED)
      continue;
    if (p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002630:	4b95                	li	s7,5
      state = states[p->state];
    else
      state = "???";
    80002632:	00006997          	auipc	s3,0x6
    80002636:	c4e98993          	addi	s3,s3,-946 # 80008280 <digits+0x240>
    printf("%d %s %s %d %d", p->pid, state, p->name, p->que_no, ticks);
    8000263a:	00006b17          	auipc	s6,0x6
    8000263e:	2c6b0b13          	addi	s6,s6,710 # 80008900 <ticks>
    80002642:	00006a97          	auipc	s5,0x6
    80002646:	c46a8a93          	addi	s5,s5,-954 # 80008288 <digits+0x248>
    printf("\n");
    8000264a:	00006a17          	auipc	s4,0x6
    8000264e:	a7ea0a13          	addi	s4,s4,-1410 # 800080c8 <digits+0x88>
    if (p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002652:	00006c17          	auipc	s8,0x6
    80002656:	c76c0c13          	addi	s8,s8,-906 # 800082c8 <states.0>
    8000265a:	a025                	j	80002682 <procdump+0x8a>
    printf("%d %s %s %d %d", p->pid, state, p->name, p->que_no, ticks);
    8000265c:	000b2783          	lw	a5,0(s6)
    80002660:	5298                	lw	a4,32(a3)
    80002662:	eb86a583          	lw	a1,-328(a3)
    80002666:	8556                	mv	a0,s5
    80002668:	ffffe097          	auipc	ra,0xffffe
    8000266c:	f22080e7          	jalr	-222(ra) # 8000058a <printf>
    printf("\n");
    80002670:	8552                	mv	a0,s4
    80002672:	ffffe097          	auipc	ra,0xffffe
    80002676:	f18080e7          	jalr	-232(ra) # 8000058a <printf>
  for (p = proc; p < &proc[NPROC]; p++)
    8000267a:	1a048493          	addi	s1,s1,416
    8000267e:	03248263          	beq	s1,s2,800026a2 <procdump+0xaa>
    if (p->state == UNUSED)
    80002682:	86a6                	mv	a3,s1
    80002684:	ea04a783          	lw	a5,-352(s1)
    80002688:	dbed                	beqz	a5,8000267a <procdump+0x82>
      state = "???";
    8000268a:	864e                	mv	a2,s3
    if (p->state >= 0 && p->state < NELEM(states) && states[p->state])
    8000268c:	fcfbe8e3          	bltu	s7,a5,8000265c <procdump+0x64>
    80002690:	02079713          	slli	a4,a5,0x20
    80002694:	01d75793          	srli	a5,a4,0x1d
    80002698:	97e2                	add	a5,a5,s8
    8000269a:	6390                	ld	a2,0(a5)
    8000269c:	f261                	bnez	a2,8000265c <procdump+0x64>
      state = "???";
    8000269e:	864e                	mv	a2,s3
    800026a0:	bf75                	j	8000265c <procdump+0x64>
  }
}
    800026a2:	60a6                	ld	ra,72(sp)
    800026a4:	6406                	ld	s0,64(sp)
    800026a6:	74e2                	ld	s1,56(sp)
    800026a8:	7942                	ld	s2,48(sp)
    800026aa:	79a2                	ld	s3,40(sp)
    800026ac:	7a02                	ld	s4,32(sp)
    800026ae:	6ae2                	ld	s5,24(sp)
    800026b0:	6b42                	ld	s6,16(sp)
    800026b2:	6ba2                	ld	s7,8(sp)
    800026b4:	6c02                	ld	s8,0(sp)
    800026b6:	6161                	addi	sp,sp,80
    800026b8:	8082                	ret

00000000800026ba <waitx>:

// waitx
int waitx(uint64 addr, uint *wtime, uint *rtime)
{
    800026ba:	711d                	addi	sp,sp,-96
    800026bc:	ec86                	sd	ra,88(sp)
    800026be:	e8a2                	sd	s0,80(sp)
    800026c0:	e4a6                	sd	s1,72(sp)
    800026c2:	e0ca                	sd	s2,64(sp)
    800026c4:	fc4e                	sd	s3,56(sp)
    800026c6:	f852                	sd	s4,48(sp)
    800026c8:	f456                	sd	s5,40(sp)
    800026ca:	f05a                	sd	s6,32(sp)
    800026cc:	ec5e                	sd	s7,24(sp)
    800026ce:	e862                	sd	s8,16(sp)
    800026d0:	e466                	sd	s9,8(sp)
    800026d2:	e06a                	sd	s10,0(sp)
    800026d4:	1080                	addi	s0,sp,96
    800026d6:	8b2a                	mv	s6,a0
    800026d8:	8bae                	mv	s7,a1
    800026da:	8c32                	mv	s8,a2
  struct proc *np;
  int havekids, pid;
  struct proc *p = myproc();
    800026dc:	fffff097          	auipc	ra,0xfffff
    800026e0:	2d0080e7          	jalr	720(ra) # 800019ac <myproc>
    800026e4:	892a                	mv	s2,a0

  acquire(&wait_lock);
    800026e6:	0000e517          	auipc	a0,0xe
    800026ea:	4a250513          	addi	a0,a0,1186 # 80010b88 <wait_lock>
    800026ee:	ffffe097          	auipc	ra,0xffffe
    800026f2:	4e8080e7          	jalr	1256(ra) # 80000bd6 <acquire>

  for (;;)
  {
    // Scan through table looking for exited children.
    havekids = 0;
    800026f6:	4c81                	li	s9,0
      {
        // make sure the child isn't still in exit() or swtch().
        acquire(&np->lock);

        havekids = 1;
        if (np->state == ZOMBIE)
    800026f8:	4a15                	li	s4,5
        havekids = 1;
    800026fa:	4a85                	li	s5,1
    for (np = proc; np < &proc[NPROC]; np++)
    800026fc:	00015997          	auipc	s3,0x15
    80002700:	0a498993          	addi	s3,s3,164 # 800177a0 <tickslock>
      release(&wait_lock);
      return -1;
    }

    // Wait for a child to exit.
    sleep(p, &wait_lock); // DOC: wait-sleep
    80002704:	0000ed17          	auipc	s10,0xe
    80002708:	484d0d13          	addi	s10,s10,1156 # 80010b88 <wait_lock>
    havekids = 0;
    8000270c:	8766                	mv	a4,s9
    for (np = proc; np < &proc[NPROC]; np++)
    8000270e:	0000f497          	auipc	s1,0xf
    80002712:	89248493          	addi	s1,s1,-1902 # 80010fa0 <proc>
    80002716:	a059                	j	8000279c <waitx+0xe2>
          pid = np->pid;
    80002718:	0304a983          	lw	s3,48(s1)
          *rtime = np->rtime;
    8000271c:	1884a783          	lw	a5,392(s1)
    80002720:	00fc2023          	sw	a5,0(s8)
          *wtime = np->etime - np->ctime - np->rtime;
    80002724:	18c4a703          	lw	a4,396(s1)
    80002728:	9f3d                	addw	a4,a4,a5
    8000272a:	1904a783          	lw	a5,400(s1)
    8000272e:	9f99                	subw	a5,a5,a4
    80002730:	00fba023          	sw	a5,0(s7)
          if (addr != 0 && copyout(p->pagetable, addr, (char *)&np->xstate,
    80002734:	000b0e63          	beqz	s6,80002750 <waitx+0x96>
    80002738:	4691                	li	a3,4
    8000273a:	02c48613          	addi	a2,s1,44
    8000273e:	85da                	mv	a1,s6
    80002740:	07093503          	ld	a0,112(s2)
    80002744:	fffff097          	auipc	ra,0xfffff
    80002748:	f28080e7          	jalr	-216(ra) # 8000166c <copyout>
    8000274c:	02054563          	bltz	a0,80002776 <waitx+0xbc>
          freeproc(np);
    80002750:	8526                	mv	a0,s1
    80002752:	fffff097          	auipc	ra,0xfffff
    80002756:	40c080e7          	jalr	1036(ra) # 80001b5e <freeproc>
          release(&np->lock);
    8000275a:	8526                	mv	a0,s1
    8000275c:	ffffe097          	auipc	ra,0xffffe
    80002760:	52e080e7          	jalr	1326(ra) # 80000c8a <release>
          release(&wait_lock);
    80002764:	0000e517          	auipc	a0,0xe
    80002768:	42450513          	addi	a0,a0,1060 # 80010b88 <wait_lock>
    8000276c:	ffffe097          	auipc	ra,0xffffe
    80002770:	51e080e7          	jalr	1310(ra) # 80000c8a <release>
          return pid;
    80002774:	a09d                	j	800027da <waitx+0x120>
            release(&np->lock);
    80002776:	8526                	mv	a0,s1
    80002778:	ffffe097          	auipc	ra,0xffffe
    8000277c:	512080e7          	jalr	1298(ra) # 80000c8a <release>
            release(&wait_lock);
    80002780:	0000e517          	auipc	a0,0xe
    80002784:	40850513          	addi	a0,a0,1032 # 80010b88 <wait_lock>
    80002788:	ffffe097          	auipc	ra,0xffffe
    8000278c:	502080e7          	jalr	1282(ra) # 80000c8a <release>
            return -1;
    80002790:	59fd                	li	s3,-1
    80002792:	a0a1                	j	800027da <waitx+0x120>
    for (np = proc; np < &proc[NPROC]; np++)
    80002794:	1a048493          	addi	s1,s1,416
    80002798:	03348463          	beq	s1,s3,800027c0 <waitx+0x106>
      if (np->parent == p)
    8000279c:	7c9c                	ld	a5,56(s1)
    8000279e:	ff279be3          	bne	a5,s2,80002794 <waitx+0xda>
        acquire(&np->lock);
    800027a2:	8526                	mv	a0,s1
    800027a4:	ffffe097          	auipc	ra,0xffffe
    800027a8:	432080e7          	jalr	1074(ra) # 80000bd6 <acquire>
        if (np->state == ZOMBIE)
    800027ac:	4c9c                	lw	a5,24(s1)
    800027ae:	f74785e3          	beq	a5,s4,80002718 <waitx+0x5e>
        release(&np->lock);
    800027b2:	8526                	mv	a0,s1
    800027b4:	ffffe097          	auipc	ra,0xffffe
    800027b8:	4d6080e7          	jalr	1238(ra) # 80000c8a <release>
        havekids = 1;
    800027bc:	8756                	mv	a4,s5
    800027be:	bfd9                	j	80002794 <waitx+0xda>
    if (!havekids || p->killed)
    800027c0:	c701                	beqz	a4,800027c8 <waitx+0x10e>
    800027c2:	02892783          	lw	a5,40(s2)
    800027c6:	cb8d                	beqz	a5,800027f8 <waitx+0x13e>
      release(&wait_lock);
    800027c8:	0000e517          	auipc	a0,0xe
    800027cc:	3c050513          	addi	a0,a0,960 # 80010b88 <wait_lock>
    800027d0:	ffffe097          	auipc	ra,0xffffe
    800027d4:	4ba080e7          	jalr	1210(ra) # 80000c8a <release>
      return -1;
    800027d8:	59fd                	li	s3,-1
  }
}
    800027da:	854e                	mv	a0,s3
    800027dc:	60e6                	ld	ra,88(sp)
    800027de:	6446                	ld	s0,80(sp)
    800027e0:	64a6                	ld	s1,72(sp)
    800027e2:	6906                	ld	s2,64(sp)
    800027e4:	79e2                	ld	s3,56(sp)
    800027e6:	7a42                	ld	s4,48(sp)
    800027e8:	7aa2                	ld	s5,40(sp)
    800027ea:	7b02                	ld	s6,32(sp)
    800027ec:	6be2                	ld	s7,24(sp)
    800027ee:	6c42                	ld	s8,16(sp)
    800027f0:	6ca2                	ld	s9,8(sp)
    800027f2:	6d02                	ld	s10,0(sp)
    800027f4:	6125                	addi	sp,sp,96
    800027f6:	8082                	ret
    sleep(p, &wait_lock); // DOC: wait-sleep
    800027f8:	85ea                	mv	a1,s10
    800027fa:	854a                	mv	a0,s2
    800027fc:	00000097          	auipc	ra,0x0
    80002800:	91c080e7          	jalr	-1764(ra) # 80002118 <sleep>
    havekids = 0;
    80002804:	b721                	j	8000270c <waitx+0x52>

0000000080002806 <update_time>:

void update_time()
{
    80002806:	7179                	addi	sp,sp,-48
    80002808:	f406                	sd	ra,40(sp)
    8000280a:	f022                	sd	s0,32(sp)
    8000280c:	ec26                	sd	s1,24(sp)
    8000280e:	e84a                	sd	s2,16(sp)
    80002810:	e44e                	sd	s3,8(sp)
    80002812:	1800                	addi	s0,sp,48
  struct proc *p;
  for (p = proc; p < &proc[NPROC]; p++)
    80002814:	0000e497          	auipc	s1,0xe
    80002818:	78c48493          	addi	s1,s1,1932 # 80010fa0 <proc>
  {
    acquire(&p->lock);
    if (p->state == RUNNING)
    8000281c:	4991                	li	s3,4
  for (p = proc; p < &proc[NPROC]; p++)
    8000281e:	00015917          	auipc	s2,0x15
    80002822:	f8290913          	addi	s2,s2,-126 # 800177a0 <tickslock>
    80002826:	a811                	j	8000283a <update_time+0x34>
    {
      p->rtime++;
    }
    release(&p->lock);
    80002828:	8526                	mv	a0,s1
    8000282a:	ffffe097          	auipc	ra,0xffffe
    8000282e:	460080e7          	jalr	1120(ra) # 80000c8a <release>
  for (p = proc; p < &proc[NPROC]; p++)
    80002832:	1a048493          	addi	s1,s1,416
    80002836:	03248063          	beq	s1,s2,80002856 <update_time+0x50>
    acquire(&p->lock);
    8000283a:	8526                	mv	a0,s1
    8000283c:	ffffe097          	auipc	ra,0xffffe
    80002840:	39a080e7          	jalr	922(ra) # 80000bd6 <acquire>
    if (p->state == RUNNING)
    80002844:	4c9c                	lw	a5,24(s1)
    80002846:	ff3791e3          	bne	a5,s3,80002828 <update_time+0x22>
      p->rtime++;
    8000284a:	1884a783          	lw	a5,392(s1)
    8000284e:	2785                	addiw	a5,a5,1
    80002850:	18f4a423          	sw	a5,392(s1)
    80002854:	bfd1                	j	80002828 <update_time+0x22>
  // for (p = proc; p < &proc[NPROC]; p++)
  // {
  //   if ((p->state == RUNNABLE || p->state == RUNNING) && (p->pid >= 9 && p->pid <= 13))
  //     printf("%d %d %d\n", p->pid, ticks, p->que_no);
  // }
}
    80002856:	70a2                	ld	ra,40(sp)
    80002858:	7402                	ld	s0,32(sp)
    8000285a:	64e2                	ld	s1,24(sp)
    8000285c:	6942                	ld	s2,16(sp)
    8000285e:	69a2                	ld	s3,8(sp)
    80002860:	6145                	addi	sp,sp,48
    80002862:	8082                	ret

0000000080002864 <swtch>:
    80002864:	00153023          	sd	ra,0(a0)
    80002868:	00253423          	sd	sp,8(a0)
    8000286c:	e900                	sd	s0,16(a0)
    8000286e:	ed04                	sd	s1,24(a0)
    80002870:	03253023          	sd	s2,32(a0)
    80002874:	03353423          	sd	s3,40(a0)
    80002878:	03453823          	sd	s4,48(a0)
    8000287c:	03553c23          	sd	s5,56(a0)
    80002880:	05653023          	sd	s6,64(a0)
    80002884:	05753423          	sd	s7,72(a0)
    80002888:	05853823          	sd	s8,80(a0)
    8000288c:	05953c23          	sd	s9,88(a0)
    80002890:	07a53023          	sd	s10,96(a0)
    80002894:	07b53423          	sd	s11,104(a0)
    80002898:	0005b083          	ld	ra,0(a1)
    8000289c:	0085b103          	ld	sp,8(a1)
    800028a0:	6980                	ld	s0,16(a1)
    800028a2:	6d84                	ld	s1,24(a1)
    800028a4:	0205b903          	ld	s2,32(a1)
    800028a8:	0285b983          	ld	s3,40(a1)
    800028ac:	0305ba03          	ld	s4,48(a1)
    800028b0:	0385ba83          	ld	s5,56(a1)
    800028b4:	0405bb03          	ld	s6,64(a1)
    800028b8:	0485bb83          	ld	s7,72(a1)
    800028bc:	0505bc03          	ld	s8,80(a1)
    800028c0:	0585bc83          	ld	s9,88(a1)
    800028c4:	0605bd03          	ld	s10,96(a1)
    800028c8:	0685bd83          	ld	s11,104(a1)
    800028cc:	8082                	ret

00000000800028ce <trapinit>:
void kernelvec();

extern int devintr();

void trapinit(void)
{
    800028ce:	1141                	addi	sp,sp,-16
    800028d0:	e406                	sd	ra,8(sp)
    800028d2:	e022                	sd	s0,0(sp)
    800028d4:	0800                	addi	s0,sp,16
  initlock(&tickslock, "time");
    800028d6:	00006597          	auipc	a1,0x6
    800028da:	a2258593          	addi	a1,a1,-1502 # 800082f8 <states.0+0x30>
    800028de:	00015517          	auipc	a0,0x15
    800028e2:	ec250513          	addi	a0,a0,-318 # 800177a0 <tickslock>
    800028e6:	ffffe097          	auipc	ra,0xffffe
    800028ea:	260080e7          	jalr	608(ra) # 80000b46 <initlock>
}
    800028ee:	60a2                	ld	ra,8(sp)
    800028f0:	6402                	ld	s0,0(sp)
    800028f2:	0141                	addi	sp,sp,16
    800028f4:	8082                	ret

00000000800028f6 <trapinithart>:

// set up to take exceptions and traps while in the kernel.
void trapinithart(void)
{
    800028f6:	1141                	addi	sp,sp,-16
    800028f8:	e422                	sd	s0,8(sp)
    800028fa:	0800                	addi	s0,sp,16
  asm volatile("csrw stvec, %0" : : "r" (x));
    800028fc:	00004797          	auipc	a5,0x4
    80002900:	97478793          	addi	a5,a5,-1676 # 80006270 <kernelvec>
    80002904:	10579073          	csrw	stvec,a5
  w_stvec((uint64)kernelvec);
}
    80002908:	6422                	ld	s0,8(sp)
    8000290a:	0141                	addi	sp,sp,16
    8000290c:	8082                	ret

000000008000290e <usertrapret>:

//
// return to user space
//
void usertrapret(void)
{
    8000290e:	1141                	addi	sp,sp,-16
    80002910:	e406                	sd	ra,8(sp)
    80002912:	e022                	sd	s0,0(sp)
    80002914:	0800                	addi	s0,sp,16
  struct proc *p = myproc();
    80002916:	fffff097          	auipc	ra,0xfffff
    8000291a:	096080e7          	jalr	150(ra) # 800019ac <myproc>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    8000291e:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    80002922:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002924:	10079073          	csrw	sstatus,a5
  // kerneltrap() to usertrap(), so turn off interrupts until
  // we're back in user space, where usertrap() is correct.
  intr_off();

  // send syscalls, interrupts, and exceptions to uservec in trampoline.S
  uint64 trampoline_uservec = TRAMPOLINE + (uservec - trampoline);
    80002928:	00004697          	auipc	a3,0x4
    8000292c:	6d868693          	addi	a3,a3,1752 # 80007000 <_trampoline>
    80002930:	00004717          	auipc	a4,0x4
    80002934:	6d070713          	addi	a4,a4,1744 # 80007000 <_trampoline>
    80002938:	8f15                	sub	a4,a4,a3
    8000293a:	040007b7          	lui	a5,0x4000
    8000293e:	17fd                	addi	a5,a5,-1 # 3ffffff <_entry-0x7c000001>
    80002940:	07b2                	slli	a5,a5,0xc
    80002942:	973e                	add	a4,a4,a5
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002944:	10571073          	csrw	stvec,a4
  w_stvec(trampoline_uservec);

  // set up trapframe values that uservec will need when
  // the process next traps into the kernel.
  p->trapframe->kernel_satp = r_satp();         // kernel page table
    80002948:	7d38                	ld	a4,120(a0)
  asm volatile("csrr %0, satp" : "=r" (x) );
    8000294a:	18002673          	csrr	a2,satp
    8000294e:	e310                	sd	a2,0(a4)
  p->trapframe->kernel_sp = p->kstack + PGSIZE; // process's kernel stack
    80002950:	7d30                	ld	a2,120(a0)
    80002952:	7138                	ld	a4,96(a0)
    80002954:	6585                	lui	a1,0x1
    80002956:	972e                	add	a4,a4,a1
    80002958:	e618                	sd	a4,8(a2)
  p->trapframe->kernel_trap = (uint64)usertrap;
    8000295a:	7d38                	ld	a4,120(a0)
    8000295c:	00000617          	auipc	a2,0x0
    80002960:	13e60613          	addi	a2,a2,318 # 80002a9a <usertrap>
    80002964:	eb10                	sd	a2,16(a4)
  p->trapframe->kernel_hartid = r_tp(); // hartid for cpuid()
    80002966:	7d38                	ld	a4,120(a0)
  asm volatile("mv %0, tp" : "=r" (x) );
    80002968:	8612                	mv	a2,tp
    8000296a:	f310                	sd	a2,32(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    8000296c:	10002773          	csrr	a4,sstatus
  // set up the registers that trampoline.S's sret will use
  // to get to user space.

  // set S Previous Privilege mode to User.
  unsigned long x = r_sstatus();
  x &= ~SSTATUS_SPP; // clear SPP to 0 for user mode
    80002970:	eff77713          	andi	a4,a4,-257
  x |= SSTATUS_SPIE; // enable interrupts in user mode
    80002974:	02076713          	ori	a4,a4,32
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002978:	10071073          	csrw	sstatus,a4
  w_sstatus(x);

  // set S Exception Program Counter to the saved user pc.
  w_sepc(p->trapframe->epc);
    8000297c:	7d38                	ld	a4,120(a0)
  asm volatile("csrw sepc, %0" : : "r" (x));
    8000297e:	6f18                	ld	a4,24(a4)
    80002980:	14171073          	csrw	sepc,a4

  // tell trampoline.S the user page table to switch to.
  uint64 satp = MAKE_SATP(p->pagetable);
    80002984:	7928                	ld	a0,112(a0)
    80002986:	8131                	srli	a0,a0,0xc

  // jump to userret in trampoline.S at the top of memory, which
  // switches to the user page table, restores user registers,
  // and switches to user mode with sret.
  uint64 trampoline_userret = TRAMPOLINE + (userret - trampoline);
    80002988:	00004717          	auipc	a4,0x4
    8000298c:	71470713          	addi	a4,a4,1812 # 8000709c <userret>
    80002990:	8f15                	sub	a4,a4,a3
    80002992:	97ba                	add	a5,a5,a4
  ((void (*)(uint64))trampoline_userret)(satp);
    80002994:	577d                	li	a4,-1
    80002996:	177e                	slli	a4,a4,0x3f
    80002998:	8d59                	or	a0,a0,a4
    8000299a:	9782                	jalr	a5
}
    8000299c:	60a2                	ld	ra,8(sp)
    8000299e:	6402                	ld	s0,0(sp)
    800029a0:	0141                	addi	sp,sp,16
    800029a2:	8082                	ret

00000000800029a4 <clockintr>:
  w_sepc(sepc);
  w_sstatus(sstatus);
}

void clockintr()
{
    800029a4:	1101                	addi	sp,sp,-32
    800029a6:	ec06                	sd	ra,24(sp)
    800029a8:	e822                	sd	s0,16(sp)
    800029aa:	e426                	sd	s1,8(sp)
    800029ac:	e04a                	sd	s2,0(sp)
    800029ae:	1000                	addi	s0,sp,32
  acquire(&tickslock);
    800029b0:	00015917          	auipc	s2,0x15
    800029b4:	df090913          	addi	s2,s2,-528 # 800177a0 <tickslock>
    800029b8:	854a                	mv	a0,s2
    800029ba:	ffffe097          	auipc	ra,0xffffe
    800029be:	21c080e7          	jalr	540(ra) # 80000bd6 <acquire>
  ticks++;
    800029c2:	00006497          	auipc	s1,0x6
    800029c6:	f3e48493          	addi	s1,s1,-194 # 80008900 <ticks>
    800029ca:	409c                	lw	a5,0(s1)
    800029cc:	2785                	addiw	a5,a5,1
    800029ce:	c09c                	sw	a5,0(s1)
  update_time();
    800029d0:	00000097          	auipc	ra,0x0
    800029d4:	e36080e7          	jalr	-458(ra) # 80002806 <update_time>
  //   // {
  //   //   p->wtime++;
  //   // }
  //   release(&p->lock);
  // }
  wakeup(&ticks);
    800029d8:	8526                	mv	a0,s1
    800029da:	fffff097          	auipc	ra,0xfffff
    800029de:	7a2080e7          	jalr	1954(ra) # 8000217c <wakeup>
  release(&tickslock);
    800029e2:	854a                	mv	a0,s2
    800029e4:	ffffe097          	auipc	ra,0xffffe
    800029e8:	2a6080e7          	jalr	678(ra) # 80000c8a <release>
}
    800029ec:	60e2                	ld	ra,24(sp)
    800029ee:	6442                	ld	s0,16(sp)
    800029f0:	64a2                	ld	s1,8(sp)
    800029f2:	6902                	ld	s2,0(sp)
    800029f4:	6105                	addi	sp,sp,32
    800029f6:	8082                	ret

00000000800029f8 <devintr>:
// and handle it.
// returns 2 if timer interrupt,
// 1 if other device,
// 0 if not recognized.
int devintr()
{
    800029f8:	1101                	addi	sp,sp,-32
    800029fa:	ec06                	sd	ra,24(sp)
    800029fc:	e822                	sd	s0,16(sp)
    800029fe:	e426                	sd	s1,8(sp)
    80002a00:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002a02:	14202773          	csrr	a4,scause
  uint64 scause = r_scause();

  if ((scause & 0x8000000000000000L) &&
    80002a06:	00074d63          	bltz	a4,80002a20 <devintr+0x28>
    if (irq)
      plic_complete(irq);

    return 1;
  }
  else if (scause == 0x8000000000000001L)
    80002a0a:	57fd                	li	a5,-1
    80002a0c:	17fe                	slli	a5,a5,0x3f
    80002a0e:	0785                	addi	a5,a5,1

    return 2;
  }
  else
  {
    return 0;
    80002a10:	4501                	li	a0,0
  else if (scause == 0x8000000000000001L)
    80002a12:	06f70363          	beq	a4,a5,80002a78 <devintr+0x80>
  }
    80002a16:	60e2                	ld	ra,24(sp)
    80002a18:	6442                	ld	s0,16(sp)
    80002a1a:	64a2                	ld	s1,8(sp)
    80002a1c:	6105                	addi	sp,sp,32
    80002a1e:	8082                	ret
      (scause & 0xff) == 9)
    80002a20:	0ff77793          	zext.b	a5,a4
  if ((scause & 0x8000000000000000L) &&
    80002a24:	46a5                	li	a3,9
    80002a26:	fed792e3          	bne	a5,a3,80002a0a <devintr+0x12>
    int irq = plic_claim();
    80002a2a:	00004097          	auipc	ra,0x4
    80002a2e:	94e080e7          	jalr	-1714(ra) # 80006378 <plic_claim>
    80002a32:	84aa                	mv	s1,a0
    if (irq == UART0_IRQ)
    80002a34:	47a9                	li	a5,10
    80002a36:	02f50763          	beq	a0,a5,80002a64 <devintr+0x6c>
    else if (irq == VIRTIO0_IRQ)
    80002a3a:	4785                	li	a5,1
    80002a3c:	02f50963          	beq	a0,a5,80002a6e <devintr+0x76>
    return 1;
    80002a40:	4505                	li	a0,1
    else if (irq)
    80002a42:	d8f1                	beqz	s1,80002a16 <devintr+0x1e>
      printf("unexpected interrupt irq=%d\n", irq);
    80002a44:	85a6                	mv	a1,s1
    80002a46:	00006517          	auipc	a0,0x6
    80002a4a:	8ba50513          	addi	a0,a0,-1862 # 80008300 <states.0+0x38>
    80002a4e:	ffffe097          	auipc	ra,0xffffe
    80002a52:	b3c080e7          	jalr	-1220(ra) # 8000058a <printf>
      plic_complete(irq);
    80002a56:	8526                	mv	a0,s1
    80002a58:	00004097          	auipc	ra,0x4
    80002a5c:	944080e7          	jalr	-1724(ra) # 8000639c <plic_complete>
    return 1;
    80002a60:	4505                	li	a0,1
    80002a62:	bf55                	j	80002a16 <devintr+0x1e>
      uartintr();
    80002a64:	ffffe097          	auipc	ra,0xffffe
    80002a68:	f34080e7          	jalr	-204(ra) # 80000998 <uartintr>
    80002a6c:	b7ed                	j	80002a56 <devintr+0x5e>
      virtio_disk_intr();
    80002a6e:	00004097          	auipc	ra,0x4
    80002a72:	df6080e7          	jalr	-522(ra) # 80006864 <virtio_disk_intr>
    80002a76:	b7c5                	j	80002a56 <devintr+0x5e>
    if (cpuid() == 0)
    80002a78:	fffff097          	auipc	ra,0xfffff
    80002a7c:	f08080e7          	jalr	-248(ra) # 80001980 <cpuid>
    80002a80:	c901                	beqz	a0,80002a90 <devintr+0x98>
  asm volatile("csrr %0, sip" : "=r" (x) );
    80002a82:	144027f3          	csrr	a5,sip
    w_sip(r_sip() & ~2);
    80002a86:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sip, %0" : : "r" (x));
    80002a88:	14479073          	csrw	sip,a5
    return 2;
    80002a8c:	4509                	li	a0,2
    80002a8e:	b761                	j	80002a16 <devintr+0x1e>
      clockintr();
    80002a90:	00000097          	auipc	ra,0x0
    80002a94:	f14080e7          	jalr	-236(ra) # 800029a4 <clockintr>
    80002a98:	b7ed                	j	80002a82 <devintr+0x8a>

0000000080002a9a <usertrap>:
{
    80002a9a:	7139                	addi	sp,sp,-64
    80002a9c:	fc06                	sd	ra,56(sp)
    80002a9e:	f822                	sd	s0,48(sp)
    80002aa0:	f426                	sd	s1,40(sp)
    80002aa2:	f04a                	sd	s2,32(sp)
    80002aa4:	ec4e                	sd	s3,24(sp)
    80002aa6:	e852                	sd	s4,16(sp)
    80002aa8:	e456                	sd	s5,8(sp)
    80002aaa:	0080                	addi	s0,sp,64
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002aac:	100027f3          	csrr	a5,sstatus
  if ((r_sstatus() & SSTATUS_SPP) != 0)
    80002ab0:	1007f793          	andi	a5,a5,256
    80002ab4:	e3b1                	bnez	a5,80002af8 <usertrap+0x5e>
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002ab6:	00003797          	auipc	a5,0x3
    80002aba:	7ba78793          	addi	a5,a5,1978 # 80006270 <kernelvec>
    80002abe:	10579073          	csrw	stvec,a5
  struct proc *p = myproc();
    80002ac2:	fffff097          	auipc	ra,0xfffff
    80002ac6:	eea080e7          	jalr	-278(ra) # 800019ac <myproc>
    80002aca:	84aa                	mv	s1,a0
  p->trapframe->epc = r_sepc();
    80002acc:	7d3c                	ld	a5,120(a0)
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002ace:	14102773          	csrr	a4,sepc
    80002ad2:	ef98                	sd	a4,24(a5)
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002ad4:	14202773          	csrr	a4,scause
  if (r_scause() == 8)
    80002ad8:	47a1                	li	a5,8
    80002ada:	02f70763          	beq	a4,a5,80002b08 <usertrap+0x6e>
  else if ((which_dev = devintr()) != 0)
    80002ade:	00000097          	auipc	ra,0x0
    80002ae2:	f1a080e7          	jalr	-230(ra) # 800029f8 <devintr>
    80002ae6:	892a                	mv	s2,a0
    80002ae8:	cd25                	beqz	a0,80002b60 <usertrap+0xc6>
  if (killed(p))
    80002aea:	8526                	mv	a0,s1
    80002aec:	00000097          	auipc	ra,0x0
    80002af0:	900080e7          	jalr	-1792(ra) # 800023ec <killed>
    80002af4:	c94d                	beqz	a0,80002ba6 <usertrap+0x10c>
    80002af6:	a05d                	j	80002b9c <usertrap+0x102>
    panic("usertrap: not from user mode");
    80002af8:	00006517          	auipc	a0,0x6
    80002afc:	82850513          	addi	a0,a0,-2008 # 80008320 <states.0+0x58>
    80002b00:	ffffe097          	auipc	ra,0xffffe
    80002b04:	a40080e7          	jalr	-1472(ra) # 80000540 <panic>
    if (killed(p))
    80002b08:	00000097          	auipc	ra,0x0
    80002b0c:	8e4080e7          	jalr	-1820(ra) # 800023ec <killed>
    80002b10:	e131                	bnez	a0,80002b54 <usertrap+0xba>
    p->trapframe->epc += 4;
    80002b12:	7cb8                	ld	a4,120(s1)
    80002b14:	6f1c                	ld	a5,24(a4)
    80002b16:	0791                	addi	a5,a5,4
    80002b18:	ef1c                	sd	a5,24(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002b1a:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80002b1e:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002b22:	10079073          	csrw	sstatus,a5
    syscall();
    80002b26:	00000097          	auipc	ra,0x0
    80002b2a:	5e8080e7          	jalr	1512(ra) # 8000310e <syscall>
  if (killed(p))
    80002b2e:	8526                	mv	a0,s1
    80002b30:	00000097          	auipc	ra,0x0
    80002b34:	8bc080e7          	jalr	-1860(ra) # 800023ec <killed>
    80002b38:	e12d                	bnez	a0,80002b9a <usertrap+0x100>
  usertrapret();
    80002b3a:	00000097          	auipc	ra,0x0
    80002b3e:	dd4080e7          	jalr	-556(ra) # 8000290e <usertrapret>
}
    80002b42:	70e2                	ld	ra,56(sp)
    80002b44:	7442                	ld	s0,48(sp)
    80002b46:	74a2                	ld	s1,40(sp)
    80002b48:	7902                	ld	s2,32(sp)
    80002b4a:	69e2                	ld	s3,24(sp)
    80002b4c:	6a42                	ld	s4,16(sp)
    80002b4e:	6aa2                	ld	s5,8(sp)
    80002b50:	6121                	addi	sp,sp,64
    80002b52:	8082                	ret
      exit(-1);
    80002b54:	557d                	li	a0,-1
    80002b56:	fffff097          	auipc	ra,0xfffff
    80002b5a:	70a080e7          	jalr	1802(ra) # 80002260 <exit>
    80002b5e:	bf55                	j	80002b12 <usertrap+0x78>
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002b60:	142025f3          	csrr	a1,scause
    printf("usertrap(): unexpected scause %p pid=%d\n", r_scause(), p->pid);
    80002b64:	5890                	lw	a2,48(s1)
    80002b66:	00005517          	auipc	a0,0x5
    80002b6a:	7da50513          	addi	a0,a0,2010 # 80008340 <states.0+0x78>
    80002b6e:	ffffe097          	auipc	ra,0xffffe
    80002b72:	a1c080e7          	jalr	-1508(ra) # 8000058a <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002b76:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002b7a:	14302673          	csrr	a2,stval
    printf("            sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002b7e:	00005517          	auipc	a0,0x5
    80002b82:	7f250513          	addi	a0,a0,2034 # 80008370 <states.0+0xa8>
    80002b86:	ffffe097          	auipc	ra,0xffffe
    80002b8a:	a04080e7          	jalr	-1532(ra) # 8000058a <printf>
    setkilled(p);
    80002b8e:	8526                	mv	a0,s1
    80002b90:	00000097          	auipc	ra,0x0
    80002b94:	830080e7          	jalr	-2000(ra) # 800023c0 <setkilled>
    80002b98:	bf59                	j	80002b2e <usertrap+0x94>
  if (killed(p))
    80002b9a:	4901                	li	s2,0
    exit(-1);
    80002b9c:	557d                	li	a0,-1
    80002b9e:	fffff097          	auipc	ra,0xfffff
    80002ba2:	6c2080e7          	jalr	1730(ra) # 80002260 <exit>
  if (which_dev == 2)
    80002ba6:	4789                	li	a5,2
    80002ba8:	f8f919e3          	bne	s2,a5,80002b3a <usertrap+0xa0>
    p->current_no_of_ticks++;
    80002bac:	44fc                	lw	a5,76(s1)
    80002bae:	2785                	addiw	a5,a5,1
    80002bb0:	0007871b          	sext.w	a4,a5
    80002bb4:	c4fc                	sw	a5,76(s1)
    if (p->alarm_status == 0)
    80002bb6:	4cbc                	lw	a5,88(s1)
    80002bb8:	e781                	bnez	a5,80002bc0 <usertrap+0x126>
      if (p->current_no_of_ticks == p->interval)
    80002bba:	44bc                	lw	a5,72(s1)
    80002bbc:	02e78663          	beq	a5,a4,80002be8 <usertrap+0x14e>
    p->counter_of_ticks++;
    80002bc0:	19c4a783          	lw	a5,412(s1)
    80002bc4:	2785                	addiw	a5,a5,1
    80002bc6:	18f4ae23          	sw	a5,412(s1)
    for (p = proc; p < &proc[NPROC]; p++)
    80002bca:	0000e497          	auipc	s1,0xe
    80002bce:	3d648493          	addi	s1,s1,982 # 80010fa0 <proc>
      if (p->state == RUNNABLE)
    80002bd2:	498d                	li	s3,3
        if (ticks - p->in_time >= 30 && p->que_no > 0)
    80002bd4:	00006a97          	auipc	s5,0x6
    80002bd8:	d2ca8a93          	addi	s5,s5,-724 # 80008900 <ticks>
    80002bdc:	4a75                	li	s4,29
    for (p = proc; p < &proc[NPROC]; p++)
    80002bde:	00015917          	auipc	s2,0x15
    80002be2:	bc290913          	addi	s2,s2,-1086 # 800177a0 <tickslock>
    80002be6:	a80d                	j	80002c18 <usertrap+0x17e>
        p->current_no_of_ticks = 0;
    80002be8:	0404a623          	sw	zero,76(s1)
        memmove(p->alarm_saving_tf, p->trapframe, PGSIZE);
    80002bec:	6605                	lui	a2,0x1
    80002bee:	7cac                	ld	a1,120(s1)
    80002bf0:	68a8                	ld	a0,80(s1)
    80002bf2:	ffffe097          	auipc	ra,0xffffe
    80002bf6:	13c080e7          	jalr	316(ra) # 80000d2e <memmove>
        p->trapframe->epc = p->handler;
    80002bfa:	7cbc                	ld	a5,120(s1)
    80002bfc:	60b8                	ld	a4,64(s1)
    80002bfe:	ef98                	sd	a4,24(a5)
        p->alarm_status = 1;
    80002c00:	4785                	li	a5,1
    80002c02:	ccbc                	sw	a5,88(s1)
    80002c04:	bf75                	j	80002bc0 <usertrap+0x126>
      release(&p->lock);
    80002c06:	8526                	mv	a0,s1
    80002c08:	ffffe097          	auipc	ra,0xffffe
    80002c0c:	082080e7          	jalr	130(ra) # 80000c8a <release>
    for (p = proc; p < &proc[NPROC]; p++)
    80002c10:	1a048493          	addi	s1,s1,416
    80002c14:	03248e63          	beq	s1,s2,80002c50 <usertrap+0x1b6>
      acquire(&p->lock);
    80002c18:	8526                	mv	a0,s1
    80002c1a:	ffffe097          	auipc	ra,0xffffe
    80002c1e:	fbc080e7          	jalr	-68(ra) # 80000bd6 <acquire>
      if (p->state == RUNNABLE)
    80002c22:	4c9c                	lw	a5,24(s1)
    80002c24:	ff3791e3          	bne	a5,s3,80002c06 <usertrap+0x16c>
        if (ticks - p->in_time >= 30 && p->que_no > 0)
    80002c28:	000aa703          	lw	a4,0(s5)
    80002c2c:	1944a783          	lw	a5,404(s1)
    80002c30:	40f707bb          	subw	a5,a4,a5
    80002c34:	fcfa79e3          	bgeu	s4,a5,80002c06 <usertrap+0x16c>
    80002c38:	1984a783          	lw	a5,408(s1)
    80002c3c:	fcf055e3          	blez	a5,80002c06 <usertrap+0x16c>
          p->in_time = ticks;
    80002c40:	18e4aa23          	sw	a4,404(s1)
          p->que_no--;
    80002c44:	37fd                	addiw	a5,a5,-1
    80002c46:	18f4ac23          	sw	a5,408(s1)
          p->counter_of_ticks = 0;
    80002c4a:	1804ae23          	sw	zero,412(s1)
    80002c4e:	bf65                	j	80002c06 <usertrap+0x16c>
    struct proc *temp = myproc();
    80002c50:	fffff097          	auipc	ra,0xfffff
    80002c54:	d5c080e7          	jalr	-676(ra) # 800019ac <myproc>
    if (temp->que_no == 0)
    80002c58:	19852783          	lw	a5,408(a0)
    80002c5c:	ef9d                	bnez	a5,80002c9a <usertrap+0x200>
      if (temp->counter_of_ticks == 1)
    80002c5e:	19c52703          	lw	a4,412(a0)
    80002c62:	4785                	li	a5,1
    80002c64:	00f70b63          	beq	a4,a5,80002c7a <usertrap+0x1e0>
    for (p = proc; p < &proc[NPROC]; p++)
    80002c68:	0000e497          	auipc	s1,0xe
    80002c6c:	33848493          	addi	s1,s1,824 # 80010fa0 <proc>
    for (p = proc; p < &proc[NPROC]; p++)
    80002c70:	00015917          	auipc	s2,0x15
    80002c74:	b3090913          	addi	s2,s2,-1232 # 800177a0 <tickslock>
    80002c78:	a855                	j	80002d2c <usertrap+0x292>
        temp->counter_of_ticks = 0;
    80002c7a:	18052e23          	sw	zero,412(a0)
        temp->in_time = ticks;
    80002c7e:	00006797          	auipc	a5,0x6
    80002c82:	c827a783          	lw	a5,-894(a5) # 80008900 <ticks>
    80002c86:	18f52a23          	sw	a5,404(a0)
        temp->que_no++;
    80002c8a:	4785                	li	a5,1
    80002c8c:	18f52c23          	sw	a5,408(a0)
        yield();
    80002c90:	fffff097          	auipc	ra,0xfffff
    80002c94:	44c080e7          	jalr	1100(ra) # 800020dc <yield>
    80002c98:	bfc1                	j	80002c68 <usertrap+0x1ce>
    else if (temp->que_no == 1)
    80002c9a:	4705                	li	a4,1
    80002c9c:	02e78a63          	beq	a5,a4,80002cd0 <usertrap+0x236>
    else if (temp->que_no == 2)
    80002ca0:	4709                	li	a4,2
    80002ca2:	04e78c63          	beq	a5,a4,80002cfa <usertrap+0x260>
    else if (temp->que_no == 3)
    80002ca6:	470d                	li	a4,3
    80002ca8:	fce790e3          	bne	a5,a4,80002c68 <usertrap+0x1ce>
      if (temp->counter_of_ticks == 15)
    80002cac:	19c52703          	lw	a4,412(a0)
    80002cb0:	47bd                	li	a5,15
    80002cb2:	faf71be3          	bne	a4,a5,80002c68 <usertrap+0x1ce>
        temp->counter_of_ticks = 0;
    80002cb6:	18052e23          	sw	zero,412(a0)
        temp->in_time = ticks;
    80002cba:	00006797          	auipc	a5,0x6
    80002cbe:	c467a783          	lw	a5,-954(a5) # 80008900 <ticks>
    80002cc2:	18f52a23          	sw	a5,404(a0)
        yield();
    80002cc6:	fffff097          	auipc	ra,0xfffff
    80002cca:	416080e7          	jalr	1046(ra) # 800020dc <yield>
    80002cce:	bf69                	j	80002c68 <usertrap+0x1ce>
      if (temp->counter_of_ticks == 3)
    80002cd0:	19c52703          	lw	a4,412(a0)
    80002cd4:	478d                	li	a5,3
    80002cd6:	f8f719e3          	bne	a4,a5,80002c68 <usertrap+0x1ce>
        temp->counter_of_ticks = 0;
    80002cda:	18052e23          	sw	zero,412(a0)
        temp->in_time = ticks;
    80002cde:	00006797          	auipc	a5,0x6
    80002ce2:	c227a783          	lw	a5,-990(a5) # 80008900 <ticks>
    80002ce6:	18f52a23          	sw	a5,404(a0)
        temp->que_no++;
    80002cea:	4789                	li	a5,2
    80002cec:	18f52c23          	sw	a5,408(a0)
        yield();
    80002cf0:	fffff097          	auipc	ra,0xfffff
    80002cf4:	3ec080e7          	jalr	1004(ra) # 800020dc <yield>
    80002cf8:	bf85                	j	80002c68 <usertrap+0x1ce>
      if (temp->counter_of_ticks == 9)
    80002cfa:	19c52703          	lw	a4,412(a0)
    80002cfe:	47a5                	li	a5,9
    80002d00:	f6f714e3          	bne	a4,a5,80002c68 <usertrap+0x1ce>
        temp->counter_of_ticks = 0;
    80002d04:	18052e23          	sw	zero,412(a0)
        temp->in_time = ticks;
    80002d08:	00006797          	auipc	a5,0x6
    80002d0c:	bf87a783          	lw	a5,-1032(a5) # 80008900 <ticks>
    80002d10:	18f52a23          	sw	a5,404(a0)
        temp->que_no++;
    80002d14:	478d                	li	a5,3
    80002d16:	18f52c23          	sw	a5,408(a0)
        yield();
    80002d1a:	fffff097          	auipc	ra,0xfffff
    80002d1e:	3c2080e7          	jalr	962(ra) # 800020dc <yield>
    80002d22:	b799                	j	80002c68 <usertrap+0x1ce>
    for (p = proc; p < &proc[NPROC]; p++)
    80002d24:	1a048493          	addi	s1,s1,416
    80002d28:	e12489e3          	beq	s1,s2,80002b3a <usertrap+0xa0>
      struct proc *p1 = myproc();
    80002d2c:	fffff097          	auipc	ra,0xfffff
    80002d30:	c80080e7          	jalr	-896(ra) # 800019ac <myproc>
      if (p->que_no < p1->que_no)
    80002d34:	1984a703          	lw	a4,408(s1)
    80002d38:	19852783          	lw	a5,408(a0)
    80002d3c:	fef754e3          	bge	a4,a5,80002d24 <usertrap+0x28a>
        yield();
    80002d40:	fffff097          	auipc	ra,0xfffff
    80002d44:	39c080e7          	jalr	924(ra) # 800020dc <yield>
    80002d48:	bff1                	j	80002d24 <usertrap+0x28a>

0000000080002d4a <kerneltrap>:
{
    80002d4a:	715d                	addi	sp,sp,-80
    80002d4c:	e486                	sd	ra,72(sp)
    80002d4e:	e0a2                	sd	s0,64(sp)
    80002d50:	fc26                	sd	s1,56(sp)
    80002d52:	f84a                	sd	s2,48(sp)
    80002d54:	f44e                	sd	s3,40(sp)
    80002d56:	f052                	sd	s4,32(sp)
    80002d58:	ec56                	sd	s5,24(sp)
    80002d5a:	e85a                	sd	s6,16(sp)
    80002d5c:	e45e                	sd	s7,8(sp)
    80002d5e:	0880                	addi	s0,sp,80
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002d60:	141029f3          	csrr	s3,sepc
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002d64:	10002973          	csrr	s2,sstatus
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002d68:	142024f3          	csrr	s1,scause
  if ((sstatus & SSTATUS_SPP) == 0)
    80002d6c:	10097793          	andi	a5,s2,256
    80002d70:	cf85                	beqz	a5,80002da8 <kerneltrap+0x5e>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002d72:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80002d76:	8b89                	andi	a5,a5,2
  if (intr_get() != 0)
    80002d78:	e3a1                	bnez	a5,80002db8 <kerneltrap+0x6e>
  if ((which_dev = devintr()) == 0)
    80002d7a:	00000097          	auipc	ra,0x0
    80002d7e:	c7e080e7          	jalr	-898(ra) # 800029f8 <devintr>
    80002d82:	c139                	beqz	a0,80002dc8 <kerneltrap+0x7e>
  if (which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80002d84:	4789                	li	a5,2
    80002d86:	06f50e63          	beq	a0,a5,80002e02 <kerneltrap+0xb8>
  asm volatile("csrw sepc, %0" : : "r" (x));
    80002d8a:	14199073          	csrw	sepc,s3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002d8e:	10091073          	csrw	sstatus,s2
}
    80002d92:	60a6                	ld	ra,72(sp)
    80002d94:	6406                	ld	s0,64(sp)
    80002d96:	74e2                	ld	s1,56(sp)
    80002d98:	7942                	ld	s2,48(sp)
    80002d9a:	79a2                	ld	s3,40(sp)
    80002d9c:	7a02                	ld	s4,32(sp)
    80002d9e:	6ae2                	ld	s5,24(sp)
    80002da0:	6b42                	ld	s6,16(sp)
    80002da2:	6ba2                	ld	s7,8(sp)
    80002da4:	6161                	addi	sp,sp,80
    80002da6:	8082                	ret
    panic("kerneltrap: not from supervisor mode");
    80002da8:	00005517          	auipc	a0,0x5
    80002dac:	5e850513          	addi	a0,a0,1512 # 80008390 <states.0+0xc8>
    80002db0:	ffffd097          	auipc	ra,0xffffd
    80002db4:	790080e7          	jalr	1936(ra) # 80000540 <panic>
    panic("kerneltrap: interrupts enabled");
    80002db8:	00005517          	auipc	a0,0x5
    80002dbc:	60050513          	addi	a0,a0,1536 # 800083b8 <states.0+0xf0>
    80002dc0:	ffffd097          	auipc	ra,0xffffd
    80002dc4:	780080e7          	jalr	1920(ra) # 80000540 <panic>
    printf("scause %p\n", scause);
    80002dc8:	85a6                	mv	a1,s1
    80002dca:	00005517          	auipc	a0,0x5
    80002dce:	60e50513          	addi	a0,a0,1550 # 800083d8 <states.0+0x110>
    80002dd2:	ffffd097          	auipc	ra,0xffffd
    80002dd6:	7b8080e7          	jalr	1976(ra) # 8000058a <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002dda:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002dde:	14302673          	csrr	a2,stval
    printf("sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002de2:	00005517          	auipc	a0,0x5
    80002de6:	60650513          	addi	a0,a0,1542 # 800083e8 <states.0+0x120>
    80002dea:	ffffd097          	auipc	ra,0xffffd
    80002dee:	7a0080e7          	jalr	1952(ra) # 8000058a <printf>
    panic("kerneltrap");
    80002df2:	00005517          	auipc	a0,0x5
    80002df6:	60e50513          	addi	a0,a0,1550 # 80008400 <states.0+0x138>
    80002dfa:	ffffd097          	auipc	ra,0xffffd
    80002dfe:	746080e7          	jalr	1862(ra) # 80000540 <panic>
  if (which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80002e02:	fffff097          	auipc	ra,0xfffff
    80002e06:	baa080e7          	jalr	-1110(ra) # 800019ac <myproc>
    80002e0a:	d141                	beqz	a0,80002d8a <kerneltrap+0x40>
    80002e0c:	fffff097          	auipc	ra,0xfffff
    80002e10:	ba0080e7          	jalr	-1120(ra) # 800019ac <myproc>
    80002e14:	4d18                	lw	a4,24(a0)
    80002e16:	4791                	li	a5,4
    80002e18:	f6f719e3          	bne	a4,a5,80002d8a <kerneltrap+0x40>
    struct proc *temp = myproc();
    80002e1c:	fffff097          	auipc	ra,0xfffff
    80002e20:	b90080e7          	jalr	-1136(ra) # 800019ac <myproc>
    temp->counter_of_ticks++;
    80002e24:	19c52783          	lw	a5,412(a0)
    80002e28:	2785                	addiw	a5,a5,1
    80002e2a:	18f52e23          	sw	a5,412(a0)
    for (p = proc; p < &proc[NPROC]; p++)
    80002e2e:	0000e497          	auipc	s1,0xe
    80002e32:	17248493          	addi	s1,s1,370 # 80010fa0 <proc>
      if (p->state == RUNNABLE)
    80002e36:	4a8d                	li	s5,3
        if (ticks - p->in_time >= 30 && p->que_no > 0)
    80002e38:	00006b97          	auipc	s7,0x6
    80002e3c:	ac8b8b93          	addi	s7,s7,-1336 # 80008900 <ticks>
    80002e40:	4b75                	li	s6,29
    for (p = proc; p < &proc[NPROC]; p++)
    80002e42:	00015a17          	auipc	s4,0x15
    80002e46:	95ea0a13          	addi	s4,s4,-1698 # 800177a0 <tickslock>
    80002e4a:	a811                	j	80002e5e <kerneltrap+0x114>
      release(&p->lock);
    80002e4c:	8526                	mv	a0,s1
    80002e4e:	ffffe097          	auipc	ra,0xffffe
    80002e52:	e3c080e7          	jalr	-452(ra) # 80000c8a <release>
    for (p = proc; p < &proc[NPROC]; p++)
    80002e56:	1a048493          	addi	s1,s1,416
    80002e5a:	03448e63          	beq	s1,s4,80002e96 <kerneltrap+0x14c>
      acquire(&p->lock);
    80002e5e:	8526                	mv	a0,s1
    80002e60:	ffffe097          	auipc	ra,0xffffe
    80002e64:	d76080e7          	jalr	-650(ra) # 80000bd6 <acquire>
      if (p->state == RUNNABLE)
    80002e68:	4c9c                	lw	a5,24(s1)
    80002e6a:	ff5791e3          	bne	a5,s5,80002e4c <kerneltrap+0x102>
        if (ticks - p->in_time >= 30 && p->que_no > 0)
    80002e6e:	000ba703          	lw	a4,0(s7)
    80002e72:	1944a783          	lw	a5,404(s1)
    80002e76:	40f707bb          	subw	a5,a4,a5
    80002e7a:	fcfb79e3          	bgeu	s6,a5,80002e4c <kerneltrap+0x102>
    80002e7e:	1984a783          	lw	a5,408(s1)
    80002e82:	fcf055e3          	blez	a5,80002e4c <kerneltrap+0x102>
          p->in_time = ticks;
    80002e86:	18e4aa23          	sw	a4,404(s1)
          p->que_no--;
    80002e8a:	37fd                	addiw	a5,a5,-1
    80002e8c:	18f4ac23          	sw	a5,408(s1)
          p->counter_of_ticks = 0;
    80002e90:	1804ae23          	sw	zero,412(s1)
    80002e94:	bf65                	j	80002e4c <kerneltrap+0x102>
    temp = myproc();
    80002e96:	fffff097          	auipc	ra,0xfffff
    80002e9a:	b16080e7          	jalr	-1258(ra) # 800019ac <myproc>
    if (temp->que_no == 0)
    80002e9e:	19852783          	lw	a5,408(a0)
    80002ea2:	ef9d                	bnez	a5,80002ee0 <kerneltrap+0x196>
      if (temp->counter_of_ticks == 1)
    80002ea4:	19c52703          	lw	a4,412(a0)
    80002ea8:	4785                	li	a5,1
    80002eaa:	00f70b63          	beq	a4,a5,80002ec0 <kerneltrap+0x176>
    for (p = proc; p < &proc[NPROC]; p++)
    80002eae:	0000e497          	auipc	s1,0xe
    80002eb2:	0f248493          	addi	s1,s1,242 # 80010fa0 <proc>
    for (p = proc; p < &proc[NPROC]; p++)
    80002eb6:	00015a17          	auipc	s4,0x15
    80002eba:	8eaa0a13          	addi	s4,s4,-1814 # 800177a0 <tickslock>
    80002ebe:	a855                	j	80002f72 <kerneltrap+0x228>
        temp->counter_of_ticks = 0;
    80002ec0:	18052e23          	sw	zero,412(a0)
        temp->in_time = ticks;
    80002ec4:	00006797          	auipc	a5,0x6
    80002ec8:	a3c7a783          	lw	a5,-1476(a5) # 80008900 <ticks>
    80002ecc:	18f52a23          	sw	a5,404(a0)
        temp->que_no++;
    80002ed0:	4785                	li	a5,1
    80002ed2:	18f52c23          	sw	a5,408(a0)
        yield();
    80002ed6:	fffff097          	auipc	ra,0xfffff
    80002eda:	206080e7          	jalr	518(ra) # 800020dc <yield>
    80002ede:	bfc1                	j	80002eae <kerneltrap+0x164>
    else if (temp->que_no == 1)
    80002ee0:	4705                	li	a4,1
    80002ee2:	02e78a63          	beq	a5,a4,80002f16 <kerneltrap+0x1cc>
    else if (temp->que_no == 2)
    80002ee6:	4709                	li	a4,2
    80002ee8:	04e78c63          	beq	a5,a4,80002f40 <kerneltrap+0x1f6>
    else if (temp->que_no == 3)
    80002eec:	470d                	li	a4,3
    80002eee:	fce790e3          	bne	a5,a4,80002eae <kerneltrap+0x164>
      if (temp->counter_of_ticks == 15)
    80002ef2:	19c52703          	lw	a4,412(a0)
    80002ef6:	47bd                	li	a5,15
    80002ef8:	faf71be3          	bne	a4,a5,80002eae <kerneltrap+0x164>
        temp->counter_of_ticks = 0;
    80002efc:	18052e23          	sw	zero,412(a0)
        temp->in_time = ticks;
    80002f00:	00006797          	auipc	a5,0x6
    80002f04:	a007a783          	lw	a5,-1536(a5) # 80008900 <ticks>
    80002f08:	18f52a23          	sw	a5,404(a0)
        yield();
    80002f0c:	fffff097          	auipc	ra,0xfffff
    80002f10:	1d0080e7          	jalr	464(ra) # 800020dc <yield>
    80002f14:	bf69                	j	80002eae <kerneltrap+0x164>
      if (temp->counter_of_ticks == 3)
    80002f16:	19c52703          	lw	a4,412(a0)
    80002f1a:	478d                	li	a5,3
    80002f1c:	f8f719e3          	bne	a4,a5,80002eae <kerneltrap+0x164>
        temp->counter_of_ticks = 0;
    80002f20:	18052e23          	sw	zero,412(a0)
        temp->in_time = ticks;
    80002f24:	00006797          	auipc	a5,0x6
    80002f28:	9dc7a783          	lw	a5,-1572(a5) # 80008900 <ticks>
    80002f2c:	18f52a23          	sw	a5,404(a0)
        temp->que_no++;
    80002f30:	4789                	li	a5,2
    80002f32:	18f52c23          	sw	a5,408(a0)
        yield();
    80002f36:	fffff097          	auipc	ra,0xfffff
    80002f3a:	1a6080e7          	jalr	422(ra) # 800020dc <yield>
    80002f3e:	bf85                	j	80002eae <kerneltrap+0x164>
      if (temp->counter_of_ticks == 9)
    80002f40:	19c52703          	lw	a4,412(a0)
    80002f44:	47a5                	li	a5,9
    80002f46:	f6f714e3          	bne	a4,a5,80002eae <kerneltrap+0x164>
        temp->counter_of_ticks = 0;
    80002f4a:	18052e23          	sw	zero,412(a0)
        temp->in_time = ticks;
    80002f4e:	00006797          	auipc	a5,0x6
    80002f52:	9b27a783          	lw	a5,-1614(a5) # 80008900 <ticks>
    80002f56:	18f52a23          	sw	a5,404(a0)
        temp->que_no++;
    80002f5a:	478d                	li	a5,3
    80002f5c:	18f52c23          	sw	a5,408(a0)
        yield();
    80002f60:	fffff097          	auipc	ra,0xfffff
    80002f64:	17c080e7          	jalr	380(ra) # 800020dc <yield>
    80002f68:	b799                	j	80002eae <kerneltrap+0x164>
    for (p = proc; p < &proc[NPROC]; p++)
    80002f6a:	1a048493          	addi	s1,s1,416
    80002f6e:	e1448ee3          	beq	s1,s4,80002d8a <kerneltrap+0x40>
      struct proc *p1 = myproc();
    80002f72:	fffff097          	auipc	ra,0xfffff
    80002f76:	a3a080e7          	jalr	-1478(ra) # 800019ac <myproc>
      if (p->que_no < p1->que_no)
    80002f7a:	1984a703          	lw	a4,408(s1)
    80002f7e:	19852783          	lw	a5,408(a0)
    80002f82:	fef754e3          	bge	a4,a5,80002f6a <kerneltrap+0x220>
        yield();
    80002f86:	fffff097          	auipc	ra,0xfffff
    80002f8a:	156080e7          	jalr	342(ra) # 800020dc <yield>
    80002f8e:	bff1                	j	80002f6a <kerneltrap+0x220>

0000000080002f90 <argraw>:
  return strlen(buf);
}

static uint64
argraw(int n)
{
    80002f90:	1101                	addi	sp,sp,-32
    80002f92:	ec06                	sd	ra,24(sp)
    80002f94:	e822                	sd	s0,16(sp)
    80002f96:	e426                	sd	s1,8(sp)
    80002f98:	1000                	addi	s0,sp,32
    80002f9a:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80002f9c:	fffff097          	auipc	ra,0xfffff
    80002fa0:	a10080e7          	jalr	-1520(ra) # 800019ac <myproc>
  switch (n) {
    80002fa4:	4795                	li	a5,5
    80002fa6:	0497e163          	bltu	a5,s1,80002fe8 <argraw+0x58>
    80002faa:	048a                	slli	s1,s1,0x2
    80002fac:	00005717          	auipc	a4,0x5
    80002fb0:	48c70713          	addi	a4,a4,1164 # 80008438 <states.0+0x170>
    80002fb4:	94ba                	add	s1,s1,a4
    80002fb6:	409c                	lw	a5,0(s1)
    80002fb8:	97ba                	add	a5,a5,a4
    80002fba:	8782                	jr	a5
  case 0:
    return p->trapframe->a0;
    80002fbc:	7d3c                	ld	a5,120(a0)
    80002fbe:	7ba8                	ld	a0,112(a5)
  case 5:
    return p->trapframe->a5;
  }
  panic("argraw");
  return -1;
}
    80002fc0:	60e2                	ld	ra,24(sp)
    80002fc2:	6442                	ld	s0,16(sp)
    80002fc4:	64a2                	ld	s1,8(sp)
    80002fc6:	6105                	addi	sp,sp,32
    80002fc8:	8082                	ret
    return p->trapframe->a1;
    80002fca:	7d3c                	ld	a5,120(a0)
    80002fcc:	7fa8                	ld	a0,120(a5)
    80002fce:	bfcd                	j	80002fc0 <argraw+0x30>
    return p->trapframe->a2;
    80002fd0:	7d3c                	ld	a5,120(a0)
    80002fd2:	63c8                	ld	a0,128(a5)
    80002fd4:	b7f5                	j	80002fc0 <argraw+0x30>
    return p->trapframe->a3;
    80002fd6:	7d3c                	ld	a5,120(a0)
    80002fd8:	67c8                	ld	a0,136(a5)
    80002fda:	b7dd                	j	80002fc0 <argraw+0x30>
    return p->trapframe->a4;
    80002fdc:	7d3c                	ld	a5,120(a0)
    80002fde:	6bc8                	ld	a0,144(a5)
    80002fe0:	b7c5                	j	80002fc0 <argraw+0x30>
    return p->trapframe->a5;
    80002fe2:	7d3c                	ld	a5,120(a0)
    80002fe4:	6fc8                	ld	a0,152(a5)
    80002fe6:	bfe9                	j	80002fc0 <argraw+0x30>
  panic("argraw");
    80002fe8:	00005517          	auipc	a0,0x5
    80002fec:	42850513          	addi	a0,a0,1064 # 80008410 <states.0+0x148>
    80002ff0:	ffffd097          	auipc	ra,0xffffd
    80002ff4:	550080e7          	jalr	1360(ra) # 80000540 <panic>

0000000080002ff8 <fetchaddr>:
{
    80002ff8:	1101                	addi	sp,sp,-32
    80002ffa:	ec06                	sd	ra,24(sp)
    80002ffc:	e822                	sd	s0,16(sp)
    80002ffe:	e426                	sd	s1,8(sp)
    80003000:	e04a                	sd	s2,0(sp)
    80003002:	1000                	addi	s0,sp,32
    80003004:	84aa                	mv	s1,a0
    80003006:	892e                	mv	s2,a1
  struct proc *p = myproc();
    80003008:	fffff097          	auipc	ra,0xfffff
    8000300c:	9a4080e7          	jalr	-1628(ra) # 800019ac <myproc>
  if(addr >= p->sz || addr+sizeof(uint64) > p->sz) // both tests needed, in case of overflow
    80003010:	753c                	ld	a5,104(a0)
    80003012:	02f4f863          	bgeu	s1,a5,80003042 <fetchaddr+0x4a>
    80003016:	00848713          	addi	a4,s1,8
    8000301a:	02e7e663          	bltu	a5,a4,80003046 <fetchaddr+0x4e>
  if(copyin(p->pagetable, (char *)ip, addr, sizeof(*ip)) != 0)
    8000301e:	46a1                	li	a3,8
    80003020:	8626                	mv	a2,s1
    80003022:	85ca                	mv	a1,s2
    80003024:	7928                	ld	a0,112(a0)
    80003026:	ffffe097          	auipc	ra,0xffffe
    8000302a:	6d2080e7          	jalr	1746(ra) # 800016f8 <copyin>
    8000302e:	00a03533          	snez	a0,a0
    80003032:	40a00533          	neg	a0,a0
}
    80003036:	60e2                	ld	ra,24(sp)
    80003038:	6442                	ld	s0,16(sp)
    8000303a:	64a2                	ld	s1,8(sp)
    8000303c:	6902                	ld	s2,0(sp)
    8000303e:	6105                	addi	sp,sp,32
    80003040:	8082                	ret
    return -1;
    80003042:	557d                	li	a0,-1
    80003044:	bfcd                	j	80003036 <fetchaddr+0x3e>
    80003046:	557d                	li	a0,-1
    80003048:	b7fd                	j	80003036 <fetchaddr+0x3e>

000000008000304a <fetchstr>:
{
    8000304a:	7179                	addi	sp,sp,-48
    8000304c:	f406                	sd	ra,40(sp)
    8000304e:	f022                	sd	s0,32(sp)
    80003050:	ec26                	sd	s1,24(sp)
    80003052:	e84a                	sd	s2,16(sp)
    80003054:	e44e                	sd	s3,8(sp)
    80003056:	1800                	addi	s0,sp,48
    80003058:	892a                	mv	s2,a0
    8000305a:	84ae                	mv	s1,a1
    8000305c:	89b2                	mv	s3,a2
  struct proc *p = myproc();
    8000305e:	fffff097          	auipc	ra,0xfffff
    80003062:	94e080e7          	jalr	-1714(ra) # 800019ac <myproc>
  if(copyinstr(p->pagetable, buf, addr, max) < 0)
    80003066:	86ce                	mv	a3,s3
    80003068:	864a                	mv	a2,s2
    8000306a:	85a6                	mv	a1,s1
    8000306c:	7928                	ld	a0,112(a0)
    8000306e:	ffffe097          	auipc	ra,0xffffe
    80003072:	718080e7          	jalr	1816(ra) # 80001786 <copyinstr>
    80003076:	00054e63          	bltz	a0,80003092 <fetchstr+0x48>
  return strlen(buf);
    8000307a:	8526                	mv	a0,s1
    8000307c:	ffffe097          	auipc	ra,0xffffe
    80003080:	dd2080e7          	jalr	-558(ra) # 80000e4e <strlen>
}
    80003084:	70a2                	ld	ra,40(sp)
    80003086:	7402                	ld	s0,32(sp)
    80003088:	64e2                	ld	s1,24(sp)
    8000308a:	6942                	ld	s2,16(sp)
    8000308c:	69a2                	ld	s3,8(sp)
    8000308e:	6145                	addi	sp,sp,48
    80003090:	8082                	ret
    return -1;
    80003092:	557d                	li	a0,-1
    80003094:	bfc5                	j	80003084 <fetchstr+0x3a>

0000000080003096 <argint>:

// Fetch the nth 32-bit system call argument.
void
argint(int n, int *ip)
{
    80003096:	1101                	addi	sp,sp,-32
    80003098:	ec06                	sd	ra,24(sp)
    8000309a:	e822                	sd	s0,16(sp)
    8000309c:	e426                	sd	s1,8(sp)
    8000309e:	1000                	addi	s0,sp,32
    800030a0:	84ae                	mv	s1,a1
  *ip = argraw(n);
    800030a2:	00000097          	auipc	ra,0x0
    800030a6:	eee080e7          	jalr	-274(ra) # 80002f90 <argraw>
    800030aa:	c088                	sw	a0,0(s1)
}
    800030ac:	60e2                	ld	ra,24(sp)
    800030ae:	6442                	ld	s0,16(sp)
    800030b0:	64a2                	ld	s1,8(sp)
    800030b2:	6105                	addi	sp,sp,32
    800030b4:	8082                	ret

00000000800030b6 <argaddr>:
// Retrieve an argument as a pointer.
// Doesn't check for legality, since
// copyin/copyout will do that.
void
argaddr(int n, uint64 *ip)
{
    800030b6:	1101                	addi	sp,sp,-32
    800030b8:	ec06                	sd	ra,24(sp)
    800030ba:	e822                	sd	s0,16(sp)
    800030bc:	e426                	sd	s1,8(sp)
    800030be:	1000                	addi	s0,sp,32
    800030c0:	84ae                	mv	s1,a1
  *ip = argraw(n);
    800030c2:	00000097          	auipc	ra,0x0
    800030c6:	ece080e7          	jalr	-306(ra) # 80002f90 <argraw>
    800030ca:	e088                	sd	a0,0(s1)
}
    800030cc:	60e2                	ld	ra,24(sp)
    800030ce:	6442                	ld	s0,16(sp)
    800030d0:	64a2                	ld	s1,8(sp)
    800030d2:	6105                	addi	sp,sp,32
    800030d4:	8082                	ret

00000000800030d6 <argstr>:
// Fetch the nth word-sized system call argument as a null-terminated string.
// Copies into buf, at most max.
// Returns string length if OK (including nul), -1 if error.
int
argstr(int n, char *buf, int max)
{
    800030d6:	7179                	addi	sp,sp,-48
    800030d8:	f406                	sd	ra,40(sp)
    800030da:	f022                	sd	s0,32(sp)
    800030dc:	ec26                	sd	s1,24(sp)
    800030de:	e84a                	sd	s2,16(sp)
    800030e0:	1800                	addi	s0,sp,48
    800030e2:	84ae                	mv	s1,a1
    800030e4:	8932                	mv	s2,a2
  uint64 addr;
  argaddr(n, &addr);
    800030e6:	fd840593          	addi	a1,s0,-40
    800030ea:	00000097          	auipc	ra,0x0
    800030ee:	fcc080e7          	jalr	-52(ra) # 800030b6 <argaddr>
  return fetchstr(addr, buf, max);
    800030f2:	864a                	mv	a2,s2
    800030f4:	85a6                	mv	a1,s1
    800030f6:	fd843503          	ld	a0,-40(s0)
    800030fa:	00000097          	auipc	ra,0x0
    800030fe:	f50080e7          	jalr	-176(ra) # 8000304a <fetchstr>
}
    80003102:	70a2                	ld	ra,40(sp)
    80003104:	7402                	ld	s0,32(sp)
    80003106:	64e2                	ld	s1,24(sp)
    80003108:	6942                	ld	s2,16(sp)
    8000310a:	6145                	addi	sp,sp,48
    8000310c:	8082                	ret

000000008000310e <syscall>:
[SYS_sigreturn]   sys_sigreturn,
};

void
syscall(void)
{
    8000310e:	1101                	addi	sp,sp,-32
    80003110:	ec06                	sd	ra,24(sp)
    80003112:	e822                	sd	s0,16(sp)
    80003114:	e426                	sd	s1,8(sp)
    80003116:	e04a                	sd	s2,0(sp)
    80003118:	1000                	addi	s0,sp,32
  int num;
  struct proc *p = myproc();
    8000311a:	fffff097          	auipc	ra,0xfffff
    8000311e:	892080e7          	jalr	-1902(ra) # 800019ac <myproc>
    80003122:	84aa                	mv	s1,a0

  num = p->trapframe->a7;
    80003124:	07853903          	ld	s2,120(a0)
    80003128:	0a893783          	ld	a5,168(s2)
    8000312c:	0007869b          	sext.w	a3,a5

  if(num == SYS_read)
    80003130:	4715                	li	a4,5
    80003132:	02e68663          	beq	a3,a4,8000315e <syscall+0x50>
  {
    counter++;
  }
  if(num == SYS_getreadcount)
    80003136:	475d                	li	a4,23
    80003138:	04e69663          	bne	a3,a4,80003184 <syscall+0x76>
  {
    p->count_of_read = counter;
    8000313c:	00005717          	auipc	a4,0x5
    80003140:	7c872703          	lw	a4,1992(a4) # 80008904 <counter>
    80003144:	d958                	sw	a4,52(a0)
  }
  if(num > 0 && num < NELEM(syscalls) && syscalls[num]) {
    80003146:	37fd                	addiw	a5,a5,-1
    80003148:	4661                	li	a2,24
    8000314a:	00000717          	auipc	a4,0x0
    8000314e:	2f870713          	addi	a4,a4,760 # 80003442 <sys_getreadcount>
    80003152:	04f66663          	bltu	a2,a5,8000319e <syscall+0x90>
    // Use num to lookup the system call function for num, call it,
    // and store its return value in p->trapframe->a0
    p->trapframe->a0 = syscalls[num]();
    80003156:	9702                	jalr	a4
    80003158:	06a93823          	sd	a0,112(s2)
    8000315c:	a8b9                	j	800031ba <syscall+0xac>
    counter++;
    8000315e:	00005617          	auipc	a2,0x5
    80003162:	7a660613          	addi	a2,a2,1958 # 80008904 <counter>
    80003166:	4218                	lw	a4,0(a2)
    80003168:	2705                	addiw	a4,a4,1
    8000316a:	c218                	sw	a4,0(a2)
  if(num > 0 && num < NELEM(syscalls) && syscalls[num]) {
    8000316c:	37fd                	addiw	a5,a5,-1
    8000316e:	4761                	li	a4,24
    80003170:	02f76763          	bltu	a4,a5,8000319e <syscall+0x90>
    80003174:	068e                	slli	a3,a3,0x3
    80003176:	00005797          	auipc	a5,0x5
    8000317a:	2da78793          	addi	a5,a5,730 # 80008450 <syscalls>
    8000317e:	97b6                	add	a5,a5,a3
    80003180:	6398                	ld	a4,0(a5)
    80003182:	bfd1                	j	80003156 <syscall+0x48>
    80003184:	37fd                	addiw	a5,a5,-1
    80003186:	4761                	li	a4,24
    80003188:	00f76b63          	bltu	a4,a5,8000319e <syscall+0x90>
    8000318c:	00369713          	slli	a4,a3,0x3
    80003190:	00005797          	auipc	a5,0x5
    80003194:	2c078793          	addi	a5,a5,704 # 80008450 <syscalls>
    80003198:	97ba                	add	a5,a5,a4
    8000319a:	6398                	ld	a4,0(a5)
    8000319c:	ff4d                	bnez	a4,80003156 <syscall+0x48>
  } else {
    printf("%d %s: unknown sys call %d\n",
    8000319e:	17848613          	addi	a2,s1,376
    800031a2:	588c                	lw	a1,48(s1)
    800031a4:	00005517          	auipc	a0,0x5
    800031a8:	27450513          	addi	a0,a0,628 # 80008418 <states.0+0x150>
    800031ac:	ffffd097          	auipc	ra,0xffffd
    800031b0:	3de080e7          	jalr	990(ra) # 8000058a <printf>
            p->pid, p->name, num);
    p->trapframe->a0 = -1;
    800031b4:	7cbc                	ld	a5,120(s1)
    800031b6:	577d                	li	a4,-1
    800031b8:	fbb8                	sd	a4,112(a5)
  }
}
    800031ba:	60e2                	ld	ra,24(sp)
    800031bc:	6442                	ld	s0,16(sp)
    800031be:	64a2                	ld	s1,8(sp)
    800031c0:	6902                	ld	s2,0(sp)
    800031c2:	6105                	addi	sp,sp,32
    800031c4:	8082                	ret

00000000800031c6 <sys_exit>:
#include "spinlock.h"
#include "proc.h"

uint64
sys_exit(void)
{
    800031c6:	1101                	addi	sp,sp,-32
    800031c8:	ec06                	sd	ra,24(sp)
    800031ca:	e822                	sd	s0,16(sp)
    800031cc:	1000                	addi	s0,sp,32
  int n;
  argint(0, &n);
    800031ce:	fec40593          	addi	a1,s0,-20
    800031d2:	4501                	li	a0,0
    800031d4:	00000097          	auipc	ra,0x0
    800031d8:	ec2080e7          	jalr	-318(ra) # 80003096 <argint>
  exit(n);
    800031dc:	fec42503          	lw	a0,-20(s0)
    800031e0:	fffff097          	auipc	ra,0xfffff
    800031e4:	080080e7          	jalr	128(ra) # 80002260 <exit>
  return 0; // not reached
}
    800031e8:	4501                	li	a0,0
    800031ea:	60e2                	ld	ra,24(sp)
    800031ec:	6442                	ld	s0,16(sp)
    800031ee:	6105                	addi	sp,sp,32
    800031f0:	8082                	ret

00000000800031f2 <sys_getpid>:

uint64
sys_getpid(void)
{
    800031f2:	1141                	addi	sp,sp,-16
    800031f4:	e406                	sd	ra,8(sp)
    800031f6:	e022                	sd	s0,0(sp)
    800031f8:	0800                	addi	s0,sp,16
  return myproc()->pid;
    800031fa:	ffffe097          	auipc	ra,0xffffe
    800031fe:	7b2080e7          	jalr	1970(ra) # 800019ac <myproc>
}
    80003202:	5908                	lw	a0,48(a0)
    80003204:	60a2                	ld	ra,8(sp)
    80003206:	6402                	ld	s0,0(sp)
    80003208:	0141                	addi	sp,sp,16
    8000320a:	8082                	ret

000000008000320c <sys_fork>:

uint64
sys_fork(void)
{
    8000320c:	1141                	addi	sp,sp,-16
    8000320e:	e406                	sd	ra,8(sp)
    80003210:	e022                	sd	s0,0(sp)
    80003212:	0800                	addi	s0,sp,16
  return fork();
    80003214:	fffff097          	auipc	ra,0xfffff
    80003218:	b8e080e7          	jalr	-1138(ra) # 80001da2 <fork>
}
    8000321c:	60a2                	ld	ra,8(sp)
    8000321e:	6402                	ld	s0,0(sp)
    80003220:	0141                	addi	sp,sp,16
    80003222:	8082                	ret

0000000080003224 <sys_wait>:

uint64
sys_wait(void)
{
    80003224:	1101                	addi	sp,sp,-32
    80003226:	ec06                	sd	ra,24(sp)
    80003228:	e822                	sd	s0,16(sp)
    8000322a:	1000                	addi	s0,sp,32
  uint64 p;
  argaddr(0, &p);
    8000322c:	fe840593          	addi	a1,s0,-24
    80003230:	4501                	li	a0,0
    80003232:	00000097          	auipc	ra,0x0
    80003236:	e84080e7          	jalr	-380(ra) # 800030b6 <argaddr>
  return wait(p);
    8000323a:	fe843503          	ld	a0,-24(s0)
    8000323e:	fffff097          	auipc	ra,0xfffff
    80003242:	1e0080e7          	jalr	480(ra) # 8000241e <wait>
}
    80003246:	60e2                	ld	ra,24(sp)
    80003248:	6442                	ld	s0,16(sp)
    8000324a:	6105                	addi	sp,sp,32
    8000324c:	8082                	ret

000000008000324e <sys_sbrk>:

uint64
sys_sbrk(void)
{
    8000324e:	7179                	addi	sp,sp,-48
    80003250:	f406                	sd	ra,40(sp)
    80003252:	f022                	sd	s0,32(sp)
    80003254:	ec26                	sd	s1,24(sp)
    80003256:	1800                	addi	s0,sp,48
  uint64 addr;
  int n;

  argint(0, &n);
    80003258:	fdc40593          	addi	a1,s0,-36
    8000325c:	4501                	li	a0,0
    8000325e:	00000097          	auipc	ra,0x0
    80003262:	e38080e7          	jalr	-456(ra) # 80003096 <argint>
  addr = myproc()->sz;
    80003266:	ffffe097          	auipc	ra,0xffffe
    8000326a:	746080e7          	jalr	1862(ra) # 800019ac <myproc>
    8000326e:	7524                	ld	s1,104(a0)
  if (growproc(n) < 0)
    80003270:	fdc42503          	lw	a0,-36(s0)
    80003274:	fffff097          	auipc	ra,0xfffff
    80003278:	ad2080e7          	jalr	-1326(ra) # 80001d46 <growproc>
    8000327c:	00054863          	bltz	a0,8000328c <sys_sbrk+0x3e>
    return -1;
  return addr;
}
    80003280:	8526                	mv	a0,s1
    80003282:	70a2                	ld	ra,40(sp)
    80003284:	7402                	ld	s0,32(sp)
    80003286:	64e2                	ld	s1,24(sp)
    80003288:	6145                	addi	sp,sp,48
    8000328a:	8082                	ret
    return -1;
    8000328c:	54fd                	li	s1,-1
    8000328e:	bfcd                	j	80003280 <sys_sbrk+0x32>

0000000080003290 <sys_sleep>:

uint64
sys_sleep(void)
{
    80003290:	7139                	addi	sp,sp,-64
    80003292:	fc06                	sd	ra,56(sp)
    80003294:	f822                	sd	s0,48(sp)
    80003296:	f426                	sd	s1,40(sp)
    80003298:	f04a                	sd	s2,32(sp)
    8000329a:	ec4e                	sd	s3,24(sp)
    8000329c:	0080                	addi	s0,sp,64
  int n;
  uint ticks0;

  argint(0, &n);
    8000329e:	fcc40593          	addi	a1,s0,-52
    800032a2:	4501                	li	a0,0
    800032a4:	00000097          	auipc	ra,0x0
    800032a8:	df2080e7          	jalr	-526(ra) # 80003096 <argint>
  acquire(&tickslock);
    800032ac:	00014517          	auipc	a0,0x14
    800032b0:	4f450513          	addi	a0,a0,1268 # 800177a0 <tickslock>
    800032b4:	ffffe097          	auipc	ra,0xffffe
    800032b8:	922080e7          	jalr	-1758(ra) # 80000bd6 <acquire>
  ticks0 = ticks;
    800032bc:	00005917          	auipc	s2,0x5
    800032c0:	64492903          	lw	s2,1604(s2) # 80008900 <ticks>
  while (ticks - ticks0 < n)
    800032c4:	fcc42783          	lw	a5,-52(s0)
    800032c8:	cf9d                	beqz	a5,80003306 <sys_sleep+0x76>
    if (killed(myproc()))
    {
      release(&tickslock);
      return -1;
    }
    sleep(&ticks, &tickslock);
    800032ca:	00014997          	auipc	s3,0x14
    800032ce:	4d698993          	addi	s3,s3,1238 # 800177a0 <tickslock>
    800032d2:	00005497          	auipc	s1,0x5
    800032d6:	62e48493          	addi	s1,s1,1582 # 80008900 <ticks>
    if (killed(myproc()))
    800032da:	ffffe097          	auipc	ra,0xffffe
    800032de:	6d2080e7          	jalr	1746(ra) # 800019ac <myproc>
    800032e2:	fffff097          	auipc	ra,0xfffff
    800032e6:	10a080e7          	jalr	266(ra) # 800023ec <killed>
    800032ea:	ed15                	bnez	a0,80003326 <sys_sleep+0x96>
    sleep(&ticks, &tickslock);
    800032ec:	85ce                	mv	a1,s3
    800032ee:	8526                	mv	a0,s1
    800032f0:	fffff097          	auipc	ra,0xfffff
    800032f4:	e28080e7          	jalr	-472(ra) # 80002118 <sleep>
  while (ticks - ticks0 < n)
    800032f8:	409c                	lw	a5,0(s1)
    800032fa:	412787bb          	subw	a5,a5,s2
    800032fe:	fcc42703          	lw	a4,-52(s0)
    80003302:	fce7ece3          	bltu	a5,a4,800032da <sys_sleep+0x4a>
  }
  release(&tickslock);
    80003306:	00014517          	auipc	a0,0x14
    8000330a:	49a50513          	addi	a0,a0,1178 # 800177a0 <tickslock>
    8000330e:	ffffe097          	auipc	ra,0xffffe
    80003312:	97c080e7          	jalr	-1668(ra) # 80000c8a <release>
  return 0;
    80003316:	4501                	li	a0,0
}
    80003318:	70e2                	ld	ra,56(sp)
    8000331a:	7442                	ld	s0,48(sp)
    8000331c:	74a2                	ld	s1,40(sp)
    8000331e:	7902                	ld	s2,32(sp)
    80003320:	69e2                	ld	s3,24(sp)
    80003322:	6121                	addi	sp,sp,64
    80003324:	8082                	ret
      release(&tickslock);
    80003326:	00014517          	auipc	a0,0x14
    8000332a:	47a50513          	addi	a0,a0,1146 # 800177a0 <tickslock>
    8000332e:	ffffe097          	auipc	ra,0xffffe
    80003332:	95c080e7          	jalr	-1700(ra) # 80000c8a <release>
      return -1;
    80003336:	557d                	li	a0,-1
    80003338:	b7c5                	j	80003318 <sys_sleep+0x88>

000000008000333a <sys_kill>:

uint64
sys_kill(void)
{
    8000333a:	1101                	addi	sp,sp,-32
    8000333c:	ec06                	sd	ra,24(sp)
    8000333e:	e822                	sd	s0,16(sp)
    80003340:	1000                	addi	s0,sp,32
  int pid;

  argint(0, &pid);
    80003342:	fec40593          	addi	a1,s0,-20
    80003346:	4501                	li	a0,0
    80003348:	00000097          	auipc	ra,0x0
    8000334c:	d4e080e7          	jalr	-690(ra) # 80003096 <argint>
  return kill(pid);
    80003350:	fec42503          	lw	a0,-20(s0)
    80003354:	fffff097          	auipc	ra,0xfffff
    80003358:	fee080e7          	jalr	-18(ra) # 80002342 <kill>
}
    8000335c:	60e2                	ld	ra,24(sp)
    8000335e:	6442                	ld	s0,16(sp)
    80003360:	6105                	addi	sp,sp,32
    80003362:	8082                	ret

0000000080003364 <sys_uptime>:

// return how many clock tick interrupts have occurred
// since start.
uint64
sys_uptime(void)
{
    80003364:	1101                	addi	sp,sp,-32
    80003366:	ec06                	sd	ra,24(sp)
    80003368:	e822                	sd	s0,16(sp)
    8000336a:	e426                	sd	s1,8(sp)
    8000336c:	1000                	addi	s0,sp,32
  uint xticks;

  acquire(&tickslock);
    8000336e:	00014517          	auipc	a0,0x14
    80003372:	43250513          	addi	a0,a0,1074 # 800177a0 <tickslock>
    80003376:	ffffe097          	auipc	ra,0xffffe
    8000337a:	860080e7          	jalr	-1952(ra) # 80000bd6 <acquire>
  xticks = ticks;
    8000337e:	00005497          	auipc	s1,0x5
    80003382:	5824a483          	lw	s1,1410(s1) # 80008900 <ticks>
  release(&tickslock);
    80003386:	00014517          	auipc	a0,0x14
    8000338a:	41a50513          	addi	a0,a0,1050 # 800177a0 <tickslock>
    8000338e:	ffffe097          	auipc	ra,0xffffe
    80003392:	8fc080e7          	jalr	-1796(ra) # 80000c8a <release>
  return xticks;
}
    80003396:	02049513          	slli	a0,s1,0x20
    8000339a:	9101                	srli	a0,a0,0x20
    8000339c:	60e2                	ld	ra,24(sp)
    8000339e:	6442                	ld	s0,16(sp)
    800033a0:	64a2                	ld	s1,8(sp)
    800033a2:	6105                	addi	sp,sp,32
    800033a4:	8082                	ret

00000000800033a6 <sys_waitx>:

uint64
sys_waitx(void)
{
    800033a6:	7139                	addi	sp,sp,-64
    800033a8:	fc06                	sd	ra,56(sp)
    800033aa:	f822                	sd	s0,48(sp)
    800033ac:	f426                	sd	s1,40(sp)
    800033ae:	f04a                	sd	s2,32(sp)
    800033b0:	0080                	addi	s0,sp,64
  uint64 addr, addr1, addr2;
  uint wtime, rtime;
  argaddr(0, &addr);
    800033b2:	fd840593          	addi	a1,s0,-40
    800033b6:	4501                	li	a0,0
    800033b8:	00000097          	auipc	ra,0x0
    800033bc:	cfe080e7          	jalr	-770(ra) # 800030b6 <argaddr>
  argaddr(1, &addr1); // user virtual memory
    800033c0:	fd040593          	addi	a1,s0,-48
    800033c4:	4505                	li	a0,1
    800033c6:	00000097          	auipc	ra,0x0
    800033ca:	cf0080e7          	jalr	-784(ra) # 800030b6 <argaddr>
  argaddr(2, &addr2);
    800033ce:	fc840593          	addi	a1,s0,-56
    800033d2:	4509                	li	a0,2
    800033d4:	00000097          	auipc	ra,0x0
    800033d8:	ce2080e7          	jalr	-798(ra) # 800030b6 <argaddr>
  int ret = waitx(addr, &wtime, &rtime);
    800033dc:	fc040613          	addi	a2,s0,-64
    800033e0:	fc440593          	addi	a1,s0,-60
    800033e4:	fd843503          	ld	a0,-40(s0)
    800033e8:	fffff097          	auipc	ra,0xfffff
    800033ec:	2d2080e7          	jalr	722(ra) # 800026ba <waitx>
    800033f0:	892a                	mv	s2,a0
  struct proc *p = myproc();
    800033f2:	ffffe097          	auipc	ra,0xffffe
    800033f6:	5ba080e7          	jalr	1466(ra) # 800019ac <myproc>
    800033fa:	84aa                	mv	s1,a0
  if (copyout(p->pagetable, addr1, (char *)&wtime, sizeof(int)) < 0)
    800033fc:	4691                	li	a3,4
    800033fe:	fc440613          	addi	a2,s0,-60
    80003402:	fd043583          	ld	a1,-48(s0)
    80003406:	7928                	ld	a0,112(a0)
    80003408:	ffffe097          	auipc	ra,0xffffe
    8000340c:	264080e7          	jalr	612(ra) # 8000166c <copyout>
    return -1;
    80003410:	57fd                	li	a5,-1
  if (copyout(p->pagetable, addr1, (char *)&wtime, sizeof(int)) < 0)
    80003412:	00054f63          	bltz	a0,80003430 <sys_waitx+0x8a>
  if (copyout(p->pagetable, addr2, (char *)&rtime, sizeof(int)) < 0)
    80003416:	4691                	li	a3,4
    80003418:	fc040613          	addi	a2,s0,-64
    8000341c:	fc843583          	ld	a1,-56(s0)
    80003420:	78a8                	ld	a0,112(s1)
    80003422:	ffffe097          	auipc	ra,0xffffe
    80003426:	24a080e7          	jalr	586(ra) # 8000166c <copyout>
    8000342a:	00054a63          	bltz	a0,8000343e <sys_waitx+0x98>
    return -1;
  return ret;
    8000342e:	87ca                	mv	a5,s2
}
    80003430:	853e                	mv	a0,a5
    80003432:	70e2                	ld	ra,56(sp)
    80003434:	7442                	ld	s0,48(sp)
    80003436:	74a2                	ld	s1,40(sp)
    80003438:	7902                	ld	s2,32(sp)
    8000343a:	6121                	addi	sp,sp,64
    8000343c:	8082                	ret
    return -1;
    8000343e:	57fd                	li	a5,-1
    80003440:	bfc5                	j	80003430 <sys_waitx+0x8a>

0000000080003442 <sys_getreadcount>:

int sys_getreadcount(void)
{
    80003442:	1141                	addi	sp,sp,-16
    80003444:	e406                	sd	ra,8(sp)
    80003446:	e022                	sd	s0,0(sp)
    80003448:	0800                	addi	s0,sp,16
  struct proc *p = myproc();
    8000344a:	ffffe097          	auipc	ra,0xffffe
    8000344e:	562080e7          	jalr	1378(ra) # 800019ac <myproc>
  return p->count_of_read;
}
    80003452:	5948                	lw	a0,52(a0)
    80003454:	60a2                	ld	ra,8(sp)
    80003456:	6402                	ld	s0,0(sp)
    80003458:	0141                	addi	sp,sp,16
    8000345a:	8082                	ret

000000008000345c <sys_sigalarm>:

int sys_sigalarm(void)
{
    8000345c:	7179                	addi	sp,sp,-48
    8000345e:	f406                	sd	ra,40(sp)
    80003460:	f022                	sd	s0,32(sp)
    80003462:	ec26                	sd	s1,24(sp)
    80003464:	1800                	addi	s0,sp,48
  struct proc *p = myproc();
    80003466:	ffffe097          	auipc	ra,0xffffe
    8000346a:	546080e7          	jalr	1350(ra) # 800019ac <myproc>
    8000346e:	84aa                	mv	s1,a0
  uint64 addr;
  int interval;

  argint(0, &interval);
    80003470:	fd440593          	addi	a1,s0,-44
    80003474:	4501                	li	a0,0
    80003476:	00000097          	auipc	ra,0x0
    8000347a:	c20080e7          	jalr	-992(ra) # 80003096 <argint>
  argaddr(1, &addr);
    8000347e:	fd840593          	addi	a1,s0,-40
    80003482:	4505                	li	a0,1
    80003484:	00000097          	auipc	ra,0x0
    80003488:	c32080e7          	jalr	-974(ra) # 800030b6 <argaddr>

  p->interval = interval;
    8000348c:	fd442783          	lw	a5,-44(s0)
    80003490:	c4bc                	sw	a5,72(s1)
  p->handler = addr;
    80003492:	fd843783          	ld	a5,-40(s0)
    80003496:	e0bc                	sd	a5,64(s1)

  p->alarm_status = 0;
    80003498:	0404ac23          	sw	zero,88(s1)
  return 0;
}
    8000349c:	4501                	li	a0,0
    8000349e:	70a2                	ld	ra,40(sp)
    800034a0:	7402                	ld	s0,32(sp)
    800034a2:	64e2                	ld	s1,24(sp)
    800034a4:	6145                	addi	sp,sp,48
    800034a6:	8082                	ret

00000000800034a8 <sys_sigreturn>:

int sys_sigreturn(void)
{
    800034a8:	1101                	addi	sp,sp,-32
    800034aa:	ec06                	sd	ra,24(sp)
    800034ac:	e822                	sd	s0,16(sp)
    800034ae:	e426                	sd	s1,8(sp)
    800034b0:	1000                	addi	s0,sp,32
  struct proc *p = myproc();
    800034b2:	ffffe097          	auipc	ra,0xffffe
    800034b6:	4fa080e7          	jalr	1274(ra) # 800019ac <myproc>
    800034ba:	84aa                	mv	s1,a0
  memmove(p->trapframe, p->alarm_saving_tf, PGSIZE);
    800034bc:	6605                	lui	a2,0x1
    800034be:	692c                	ld	a1,80(a0)
    800034c0:	7d28                	ld	a0,120(a0)
    800034c2:	ffffe097          	auipc	ra,0xffffe
    800034c6:	86c080e7          	jalr	-1940(ra) # 80000d2e <memmove>

  p->alarm_status = 0;
    800034ca:	0404ac23          	sw	zero,88(s1)
  p->current_no_of_ticks = 0;
    800034ce:	0404a623          	sw	zero,76(s1)
  usertrapret();
    800034d2:	fffff097          	auipc	ra,0xfffff
    800034d6:	43c080e7          	jalr	1084(ra) # 8000290e <usertrapret>
  return 0;
    800034da:	4501                	li	a0,0
    800034dc:	60e2                	ld	ra,24(sp)
    800034de:	6442                	ld	s0,16(sp)
    800034e0:	64a2                	ld	s1,8(sp)
    800034e2:	6105                	addi	sp,sp,32
    800034e4:	8082                	ret

00000000800034e6 <binit>:
  struct buf head;
} bcache;

void
binit(void)
{
    800034e6:	7179                	addi	sp,sp,-48
    800034e8:	f406                	sd	ra,40(sp)
    800034ea:	f022                	sd	s0,32(sp)
    800034ec:	ec26                	sd	s1,24(sp)
    800034ee:	e84a                	sd	s2,16(sp)
    800034f0:	e44e                	sd	s3,8(sp)
    800034f2:	e052                	sd	s4,0(sp)
    800034f4:	1800                	addi	s0,sp,48
  struct buf *b;

  initlock(&bcache.lock, "bcache");
    800034f6:	00005597          	auipc	a1,0x5
    800034fa:	02a58593          	addi	a1,a1,42 # 80008520 <syscalls+0xd0>
    800034fe:	00014517          	auipc	a0,0x14
    80003502:	2ba50513          	addi	a0,a0,698 # 800177b8 <bcache>
    80003506:	ffffd097          	auipc	ra,0xffffd
    8000350a:	640080e7          	jalr	1600(ra) # 80000b46 <initlock>

  // Create linked list of buffers
  bcache.head.prev = &bcache.head;
    8000350e:	0001c797          	auipc	a5,0x1c
    80003512:	2aa78793          	addi	a5,a5,682 # 8001f7b8 <bcache+0x8000>
    80003516:	0001c717          	auipc	a4,0x1c
    8000351a:	50a70713          	addi	a4,a4,1290 # 8001fa20 <bcache+0x8268>
    8000351e:	2ae7b823          	sd	a4,688(a5)
  bcache.head.next = &bcache.head;
    80003522:	2ae7bc23          	sd	a4,696(a5)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80003526:	00014497          	auipc	s1,0x14
    8000352a:	2aa48493          	addi	s1,s1,682 # 800177d0 <bcache+0x18>
    b->next = bcache.head.next;
    8000352e:	893e                	mv	s2,a5
    b->prev = &bcache.head;
    80003530:	89ba                	mv	s3,a4
    initsleeplock(&b->lock, "buffer");
    80003532:	00005a17          	auipc	s4,0x5
    80003536:	ff6a0a13          	addi	s4,s4,-10 # 80008528 <syscalls+0xd8>
    b->next = bcache.head.next;
    8000353a:	2b893783          	ld	a5,696(s2)
    8000353e:	e8bc                	sd	a5,80(s1)
    b->prev = &bcache.head;
    80003540:	0534b423          	sd	s3,72(s1)
    initsleeplock(&b->lock, "buffer");
    80003544:	85d2                	mv	a1,s4
    80003546:	01048513          	addi	a0,s1,16
    8000354a:	00001097          	auipc	ra,0x1
    8000354e:	4c8080e7          	jalr	1224(ra) # 80004a12 <initsleeplock>
    bcache.head.next->prev = b;
    80003552:	2b893783          	ld	a5,696(s2)
    80003556:	e7a4                	sd	s1,72(a5)
    bcache.head.next = b;
    80003558:	2a993c23          	sd	s1,696(s2)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    8000355c:	45848493          	addi	s1,s1,1112
    80003560:	fd349de3          	bne	s1,s3,8000353a <binit+0x54>
  }
}
    80003564:	70a2                	ld	ra,40(sp)
    80003566:	7402                	ld	s0,32(sp)
    80003568:	64e2                	ld	s1,24(sp)
    8000356a:	6942                	ld	s2,16(sp)
    8000356c:	69a2                	ld	s3,8(sp)
    8000356e:	6a02                	ld	s4,0(sp)
    80003570:	6145                	addi	sp,sp,48
    80003572:	8082                	ret

0000000080003574 <bread>:
}

// Return a locked buf with the contents of the indicated block.
struct buf*
bread(uint dev, uint blockno)
{
    80003574:	7179                	addi	sp,sp,-48
    80003576:	f406                	sd	ra,40(sp)
    80003578:	f022                	sd	s0,32(sp)
    8000357a:	ec26                	sd	s1,24(sp)
    8000357c:	e84a                	sd	s2,16(sp)
    8000357e:	e44e                	sd	s3,8(sp)
    80003580:	1800                	addi	s0,sp,48
    80003582:	892a                	mv	s2,a0
    80003584:	89ae                	mv	s3,a1
  acquire(&bcache.lock);
    80003586:	00014517          	auipc	a0,0x14
    8000358a:	23250513          	addi	a0,a0,562 # 800177b8 <bcache>
    8000358e:	ffffd097          	auipc	ra,0xffffd
    80003592:	648080e7          	jalr	1608(ra) # 80000bd6 <acquire>
  for(b = bcache.head.next; b != &bcache.head; b = b->next){
    80003596:	0001c497          	auipc	s1,0x1c
    8000359a:	4da4b483          	ld	s1,1242(s1) # 8001fa70 <bcache+0x82b8>
    8000359e:	0001c797          	auipc	a5,0x1c
    800035a2:	48278793          	addi	a5,a5,1154 # 8001fa20 <bcache+0x8268>
    800035a6:	02f48f63          	beq	s1,a5,800035e4 <bread+0x70>
    800035aa:	873e                	mv	a4,a5
    800035ac:	a021                	j	800035b4 <bread+0x40>
    800035ae:	68a4                	ld	s1,80(s1)
    800035b0:	02e48a63          	beq	s1,a4,800035e4 <bread+0x70>
    if(b->dev == dev && b->blockno == blockno){
    800035b4:	449c                	lw	a5,8(s1)
    800035b6:	ff279ce3          	bne	a5,s2,800035ae <bread+0x3a>
    800035ba:	44dc                	lw	a5,12(s1)
    800035bc:	ff3799e3          	bne	a5,s3,800035ae <bread+0x3a>
      b->refcnt++;
    800035c0:	40bc                	lw	a5,64(s1)
    800035c2:	2785                	addiw	a5,a5,1
    800035c4:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    800035c6:	00014517          	auipc	a0,0x14
    800035ca:	1f250513          	addi	a0,a0,498 # 800177b8 <bcache>
    800035ce:	ffffd097          	auipc	ra,0xffffd
    800035d2:	6bc080e7          	jalr	1724(ra) # 80000c8a <release>
      acquiresleep(&b->lock);
    800035d6:	01048513          	addi	a0,s1,16
    800035da:	00001097          	auipc	ra,0x1
    800035de:	472080e7          	jalr	1138(ra) # 80004a4c <acquiresleep>
      return b;
    800035e2:	a8b9                	j	80003640 <bread+0xcc>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    800035e4:	0001c497          	auipc	s1,0x1c
    800035e8:	4844b483          	ld	s1,1156(s1) # 8001fa68 <bcache+0x82b0>
    800035ec:	0001c797          	auipc	a5,0x1c
    800035f0:	43478793          	addi	a5,a5,1076 # 8001fa20 <bcache+0x8268>
    800035f4:	00f48863          	beq	s1,a5,80003604 <bread+0x90>
    800035f8:	873e                	mv	a4,a5
    if(b->refcnt == 0) {
    800035fa:	40bc                	lw	a5,64(s1)
    800035fc:	cf81                	beqz	a5,80003614 <bread+0xa0>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    800035fe:	64a4                	ld	s1,72(s1)
    80003600:	fee49de3          	bne	s1,a4,800035fa <bread+0x86>
  panic("bget: no buffers");
    80003604:	00005517          	auipc	a0,0x5
    80003608:	f2c50513          	addi	a0,a0,-212 # 80008530 <syscalls+0xe0>
    8000360c:	ffffd097          	auipc	ra,0xffffd
    80003610:	f34080e7          	jalr	-204(ra) # 80000540 <panic>
      b->dev = dev;
    80003614:	0124a423          	sw	s2,8(s1)
      b->blockno = blockno;
    80003618:	0134a623          	sw	s3,12(s1)
      b->valid = 0;
    8000361c:	0004a023          	sw	zero,0(s1)
      b->refcnt = 1;
    80003620:	4785                	li	a5,1
    80003622:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    80003624:	00014517          	auipc	a0,0x14
    80003628:	19450513          	addi	a0,a0,404 # 800177b8 <bcache>
    8000362c:	ffffd097          	auipc	ra,0xffffd
    80003630:	65e080e7          	jalr	1630(ra) # 80000c8a <release>
      acquiresleep(&b->lock);
    80003634:	01048513          	addi	a0,s1,16
    80003638:	00001097          	auipc	ra,0x1
    8000363c:	414080e7          	jalr	1044(ra) # 80004a4c <acquiresleep>
  struct buf *b;

  b = bget(dev, blockno);
  if(!b->valid) {
    80003640:	409c                	lw	a5,0(s1)
    80003642:	cb89                	beqz	a5,80003654 <bread+0xe0>
    virtio_disk_rw(b, 0);
    b->valid = 1;
  }
  return b;
}
    80003644:	8526                	mv	a0,s1
    80003646:	70a2                	ld	ra,40(sp)
    80003648:	7402                	ld	s0,32(sp)
    8000364a:	64e2                	ld	s1,24(sp)
    8000364c:	6942                	ld	s2,16(sp)
    8000364e:	69a2                	ld	s3,8(sp)
    80003650:	6145                	addi	sp,sp,48
    80003652:	8082                	ret
    virtio_disk_rw(b, 0);
    80003654:	4581                	li	a1,0
    80003656:	8526                	mv	a0,s1
    80003658:	00003097          	auipc	ra,0x3
    8000365c:	fda080e7          	jalr	-38(ra) # 80006632 <virtio_disk_rw>
    b->valid = 1;
    80003660:	4785                	li	a5,1
    80003662:	c09c                	sw	a5,0(s1)
  return b;
    80003664:	b7c5                	j	80003644 <bread+0xd0>

0000000080003666 <bwrite>:

// Write b's contents to disk.  Must be locked.
void
bwrite(struct buf *b)
{
    80003666:	1101                	addi	sp,sp,-32
    80003668:	ec06                	sd	ra,24(sp)
    8000366a:	e822                	sd	s0,16(sp)
    8000366c:	e426                	sd	s1,8(sp)
    8000366e:	1000                	addi	s0,sp,32
    80003670:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    80003672:	0541                	addi	a0,a0,16
    80003674:	00001097          	auipc	ra,0x1
    80003678:	472080e7          	jalr	1138(ra) # 80004ae6 <holdingsleep>
    8000367c:	cd01                	beqz	a0,80003694 <bwrite+0x2e>
    panic("bwrite");
  virtio_disk_rw(b, 1);
    8000367e:	4585                	li	a1,1
    80003680:	8526                	mv	a0,s1
    80003682:	00003097          	auipc	ra,0x3
    80003686:	fb0080e7          	jalr	-80(ra) # 80006632 <virtio_disk_rw>
}
    8000368a:	60e2                	ld	ra,24(sp)
    8000368c:	6442                	ld	s0,16(sp)
    8000368e:	64a2                	ld	s1,8(sp)
    80003690:	6105                	addi	sp,sp,32
    80003692:	8082                	ret
    panic("bwrite");
    80003694:	00005517          	auipc	a0,0x5
    80003698:	eb450513          	addi	a0,a0,-332 # 80008548 <syscalls+0xf8>
    8000369c:	ffffd097          	auipc	ra,0xffffd
    800036a0:	ea4080e7          	jalr	-348(ra) # 80000540 <panic>

00000000800036a4 <brelse>:

// Release a locked buffer.
// Move to the head of the most-recently-used list.
void
brelse(struct buf *b)
{
    800036a4:	1101                	addi	sp,sp,-32
    800036a6:	ec06                	sd	ra,24(sp)
    800036a8:	e822                	sd	s0,16(sp)
    800036aa:	e426                	sd	s1,8(sp)
    800036ac:	e04a                	sd	s2,0(sp)
    800036ae:	1000                	addi	s0,sp,32
    800036b0:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    800036b2:	01050913          	addi	s2,a0,16
    800036b6:	854a                	mv	a0,s2
    800036b8:	00001097          	auipc	ra,0x1
    800036bc:	42e080e7          	jalr	1070(ra) # 80004ae6 <holdingsleep>
    800036c0:	c92d                	beqz	a0,80003732 <brelse+0x8e>
    panic("brelse");

  releasesleep(&b->lock);
    800036c2:	854a                	mv	a0,s2
    800036c4:	00001097          	auipc	ra,0x1
    800036c8:	3de080e7          	jalr	990(ra) # 80004aa2 <releasesleep>

  acquire(&bcache.lock);
    800036cc:	00014517          	auipc	a0,0x14
    800036d0:	0ec50513          	addi	a0,a0,236 # 800177b8 <bcache>
    800036d4:	ffffd097          	auipc	ra,0xffffd
    800036d8:	502080e7          	jalr	1282(ra) # 80000bd6 <acquire>
  b->refcnt--;
    800036dc:	40bc                	lw	a5,64(s1)
    800036de:	37fd                	addiw	a5,a5,-1
    800036e0:	0007871b          	sext.w	a4,a5
    800036e4:	c0bc                	sw	a5,64(s1)
  if (b->refcnt == 0) {
    800036e6:	eb05                	bnez	a4,80003716 <brelse+0x72>
    // no one is waiting for it.
    b->next->prev = b->prev;
    800036e8:	68bc                	ld	a5,80(s1)
    800036ea:	64b8                	ld	a4,72(s1)
    800036ec:	e7b8                	sd	a4,72(a5)
    b->prev->next = b->next;
    800036ee:	64bc                	ld	a5,72(s1)
    800036f0:	68b8                	ld	a4,80(s1)
    800036f2:	ebb8                	sd	a4,80(a5)
    b->next = bcache.head.next;
    800036f4:	0001c797          	auipc	a5,0x1c
    800036f8:	0c478793          	addi	a5,a5,196 # 8001f7b8 <bcache+0x8000>
    800036fc:	2b87b703          	ld	a4,696(a5)
    80003700:	e8b8                	sd	a4,80(s1)
    b->prev = &bcache.head;
    80003702:	0001c717          	auipc	a4,0x1c
    80003706:	31e70713          	addi	a4,a4,798 # 8001fa20 <bcache+0x8268>
    8000370a:	e4b8                	sd	a4,72(s1)
    bcache.head.next->prev = b;
    8000370c:	2b87b703          	ld	a4,696(a5)
    80003710:	e724                	sd	s1,72(a4)
    bcache.head.next = b;
    80003712:	2a97bc23          	sd	s1,696(a5)
  }
  
  release(&bcache.lock);
    80003716:	00014517          	auipc	a0,0x14
    8000371a:	0a250513          	addi	a0,a0,162 # 800177b8 <bcache>
    8000371e:	ffffd097          	auipc	ra,0xffffd
    80003722:	56c080e7          	jalr	1388(ra) # 80000c8a <release>
}
    80003726:	60e2                	ld	ra,24(sp)
    80003728:	6442                	ld	s0,16(sp)
    8000372a:	64a2                	ld	s1,8(sp)
    8000372c:	6902                	ld	s2,0(sp)
    8000372e:	6105                	addi	sp,sp,32
    80003730:	8082                	ret
    panic("brelse");
    80003732:	00005517          	auipc	a0,0x5
    80003736:	e1e50513          	addi	a0,a0,-482 # 80008550 <syscalls+0x100>
    8000373a:	ffffd097          	auipc	ra,0xffffd
    8000373e:	e06080e7          	jalr	-506(ra) # 80000540 <panic>

0000000080003742 <bpin>:

void
bpin(struct buf *b) {
    80003742:	1101                	addi	sp,sp,-32
    80003744:	ec06                	sd	ra,24(sp)
    80003746:	e822                	sd	s0,16(sp)
    80003748:	e426                	sd	s1,8(sp)
    8000374a:	1000                	addi	s0,sp,32
    8000374c:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    8000374e:	00014517          	auipc	a0,0x14
    80003752:	06a50513          	addi	a0,a0,106 # 800177b8 <bcache>
    80003756:	ffffd097          	auipc	ra,0xffffd
    8000375a:	480080e7          	jalr	1152(ra) # 80000bd6 <acquire>
  b->refcnt++;
    8000375e:	40bc                	lw	a5,64(s1)
    80003760:	2785                	addiw	a5,a5,1
    80003762:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    80003764:	00014517          	auipc	a0,0x14
    80003768:	05450513          	addi	a0,a0,84 # 800177b8 <bcache>
    8000376c:	ffffd097          	auipc	ra,0xffffd
    80003770:	51e080e7          	jalr	1310(ra) # 80000c8a <release>
}
    80003774:	60e2                	ld	ra,24(sp)
    80003776:	6442                	ld	s0,16(sp)
    80003778:	64a2                	ld	s1,8(sp)
    8000377a:	6105                	addi	sp,sp,32
    8000377c:	8082                	ret

000000008000377e <bunpin>:

void
bunpin(struct buf *b) {
    8000377e:	1101                	addi	sp,sp,-32
    80003780:	ec06                	sd	ra,24(sp)
    80003782:	e822                	sd	s0,16(sp)
    80003784:	e426                	sd	s1,8(sp)
    80003786:	1000                	addi	s0,sp,32
    80003788:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    8000378a:	00014517          	auipc	a0,0x14
    8000378e:	02e50513          	addi	a0,a0,46 # 800177b8 <bcache>
    80003792:	ffffd097          	auipc	ra,0xffffd
    80003796:	444080e7          	jalr	1092(ra) # 80000bd6 <acquire>
  b->refcnt--;
    8000379a:	40bc                	lw	a5,64(s1)
    8000379c:	37fd                	addiw	a5,a5,-1
    8000379e:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    800037a0:	00014517          	auipc	a0,0x14
    800037a4:	01850513          	addi	a0,a0,24 # 800177b8 <bcache>
    800037a8:	ffffd097          	auipc	ra,0xffffd
    800037ac:	4e2080e7          	jalr	1250(ra) # 80000c8a <release>
}
    800037b0:	60e2                	ld	ra,24(sp)
    800037b2:	6442                	ld	s0,16(sp)
    800037b4:	64a2                	ld	s1,8(sp)
    800037b6:	6105                	addi	sp,sp,32
    800037b8:	8082                	ret

00000000800037ba <bfree>:
}

// Free a disk block.
static void
bfree(int dev, uint b)
{
    800037ba:	1101                	addi	sp,sp,-32
    800037bc:	ec06                	sd	ra,24(sp)
    800037be:	e822                	sd	s0,16(sp)
    800037c0:	e426                	sd	s1,8(sp)
    800037c2:	e04a                	sd	s2,0(sp)
    800037c4:	1000                	addi	s0,sp,32
    800037c6:	84ae                	mv	s1,a1
  struct buf *bp;
  int bi, m;

  bp = bread(dev, BBLOCK(b, sb));
    800037c8:	00d5d59b          	srliw	a1,a1,0xd
    800037cc:	0001c797          	auipc	a5,0x1c
    800037d0:	6c87a783          	lw	a5,1736(a5) # 8001fe94 <sb+0x1c>
    800037d4:	9dbd                	addw	a1,a1,a5
    800037d6:	00000097          	auipc	ra,0x0
    800037da:	d9e080e7          	jalr	-610(ra) # 80003574 <bread>
  bi = b % BPB;
  m = 1 << (bi % 8);
    800037de:	0074f713          	andi	a4,s1,7
    800037e2:	4785                	li	a5,1
    800037e4:	00e797bb          	sllw	a5,a5,a4
  if((bp->data[bi/8] & m) == 0)
    800037e8:	14ce                	slli	s1,s1,0x33
    800037ea:	90d9                	srli	s1,s1,0x36
    800037ec:	00950733          	add	a4,a0,s1
    800037f0:	05874703          	lbu	a4,88(a4)
    800037f4:	00e7f6b3          	and	a3,a5,a4
    800037f8:	c69d                	beqz	a3,80003826 <bfree+0x6c>
    800037fa:	892a                	mv	s2,a0
    panic("freeing free block");
  bp->data[bi/8] &= ~m;
    800037fc:	94aa                	add	s1,s1,a0
    800037fe:	fff7c793          	not	a5,a5
    80003802:	8f7d                	and	a4,a4,a5
    80003804:	04e48c23          	sb	a4,88(s1)
  log_write(bp);
    80003808:	00001097          	auipc	ra,0x1
    8000380c:	126080e7          	jalr	294(ra) # 8000492e <log_write>
  brelse(bp);
    80003810:	854a                	mv	a0,s2
    80003812:	00000097          	auipc	ra,0x0
    80003816:	e92080e7          	jalr	-366(ra) # 800036a4 <brelse>
}
    8000381a:	60e2                	ld	ra,24(sp)
    8000381c:	6442                	ld	s0,16(sp)
    8000381e:	64a2                	ld	s1,8(sp)
    80003820:	6902                	ld	s2,0(sp)
    80003822:	6105                	addi	sp,sp,32
    80003824:	8082                	ret
    panic("freeing free block");
    80003826:	00005517          	auipc	a0,0x5
    8000382a:	d3250513          	addi	a0,a0,-718 # 80008558 <syscalls+0x108>
    8000382e:	ffffd097          	auipc	ra,0xffffd
    80003832:	d12080e7          	jalr	-750(ra) # 80000540 <panic>

0000000080003836 <balloc>:
{
    80003836:	711d                	addi	sp,sp,-96
    80003838:	ec86                	sd	ra,88(sp)
    8000383a:	e8a2                	sd	s0,80(sp)
    8000383c:	e4a6                	sd	s1,72(sp)
    8000383e:	e0ca                	sd	s2,64(sp)
    80003840:	fc4e                	sd	s3,56(sp)
    80003842:	f852                	sd	s4,48(sp)
    80003844:	f456                	sd	s5,40(sp)
    80003846:	f05a                	sd	s6,32(sp)
    80003848:	ec5e                	sd	s7,24(sp)
    8000384a:	e862                	sd	s8,16(sp)
    8000384c:	e466                	sd	s9,8(sp)
    8000384e:	1080                	addi	s0,sp,96
  for(b = 0; b < sb.size; b += BPB){
    80003850:	0001c797          	auipc	a5,0x1c
    80003854:	62c7a783          	lw	a5,1580(a5) # 8001fe7c <sb+0x4>
    80003858:	cff5                	beqz	a5,80003954 <balloc+0x11e>
    8000385a:	8baa                	mv	s7,a0
    8000385c:	4a81                	li	s5,0
    bp = bread(dev, BBLOCK(b, sb));
    8000385e:	0001cb17          	auipc	s6,0x1c
    80003862:	61ab0b13          	addi	s6,s6,1562 # 8001fe78 <sb>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003866:	4c01                	li	s8,0
      m = 1 << (bi % 8);
    80003868:	4985                	li	s3,1
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    8000386a:	6a09                	lui	s4,0x2
  for(b = 0; b < sb.size; b += BPB){
    8000386c:	6c89                	lui	s9,0x2
    8000386e:	a061                	j	800038f6 <balloc+0xc0>
        bp->data[bi/8] |= m;  // Mark block in use.
    80003870:	97ca                	add	a5,a5,s2
    80003872:	8e55                	or	a2,a2,a3
    80003874:	04c78c23          	sb	a2,88(a5)
        log_write(bp);
    80003878:	854a                	mv	a0,s2
    8000387a:	00001097          	auipc	ra,0x1
    8000387e:	0b4080e7          	jalr	180(ra) # 8000492e <log_write>
        brelse(bp);
    80003882:	854a                	mv	a0,s2
    80003884:	00000097          	auipc	ra,0x0
    80003888:	e20080e7          	jalr	-480(ra) # 800036a4 <brelse>
  bp = bread(dev, bno);
    8000388c:	85a6                	mv	a1,s1
    8000388e:	855e                	mv	a0,s7
    80003890:	00000097          	auipc	ra,0x0
    80003894:	ce4080e7          	jalr	-796(ra) # 80003574 <bread>
    80003898:	892a                	mv	s2,a0
  memset(bp->data, 0, BSIZE);
    8000389a:	40000613          	li	a2,1024
    8000389e:	4581                	li	a1,0
    800038a0:	05850513          	addi	a0,a0,88
    800038a4:	ffffd097          	auipc	ra,0xffffd
    800038a8:	42e080e7          	jalr	1070(ra) # 80000cd2 <memset>
  log_write(bp);
    800038ac:	854a                	mv	a0,s2
    800038ae:	00001097          	auipc	ra,0x1
    800038b2:	080080e7          	jalr	128(ra) # 8000492e <log_write>
  brelse(bp);
    800038b6:	854a                	mv	a0,s2
    800038b8:	00000097          	auipc	ra,0x0
    800038bc:	dec080e7          	jalr	-532(ra) # 800036a4 <brelse>
}
    800038c0:	8526                	mv	a0,s1
    800038c2:	60e6                	ld	ra,88(sp)
    800038c4:	6446                	ld	s0,80(sp)
    800038c6:	64a6                	ld	s1,72(sp)
    800038c8:	6906                	ld	s2,64(sp)
    800038ca:	79e2                	ld	s3,56(sp)
    800038cc:	7a42                	ld	s4,48(sp)
    800038ce:	7aa2                	ld	s5,40(sp)
    800038d0:	7b02                	ld	s6,32(sp)
    800038d2:	6be2                	ld	s7,24(sp)
    800038d4:	6c42                	ld	s8,16(sp)
    800038d6:	6ca2                	ld	s9,8(sp)
    800038d8:	6125                	addi	sp,sp,96
    800038da:	8082                	ret
    brelse(bp);
    800038dc:	854a                	mv	a0,s2
    800038de:	00000097          	auipc	ra,0x0
    800038e2:	dc6080e7          	jalr	-570(ra) # 800036a4 <brelse>
  for(b = 0; b < sb.size; b += BPB){
    800038e6:	015c87bb          	addw	a5,s9,s5
    800038ea:	00078a9b          	sext.w	s5,a5
    800038ee:	004b2703          	lw	a4,4(s6)
    800038f2:	06eaf163          	bgeu	s5,a4,80003954 <balloc+0x11e>
    bp = bread(dev, BBLOCK(b, sb));
    800038f6:	41fad79b          	sraiw	a5,s5,0x1f
    800038fa:	0137d79b          	srliw	a5,a5,0x13
    800038fe:	015787bb          	addw	a5,a5,s5
    80003902:	40d7d79b          	sraiw	a5,a5,0xd
    80003906:	01cb2583          	lw	a1,28(s6)
    8000390a:	9dbd                	addw	a1,a1,a5
    8000390c:	855e                	mv	a0,s7
    8000390e:	00000097          	auipc	ra,0x0
    80003912:	c66080e7          	jalr	-922(ra) # 80003574 <bread>
    80003916:	892a                	mv	s2,a0
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003918:	004b2503          	lw	a0,4(s6)
    8000391c:	000a849b          	sext.w	s1,s5
    80003920:	8762                	mv	a4,s8
    80003922:	faa4fde3          	bgeu	s1,a0,800038dc <balloc+0xa6>
      m = 1 << (bi % 8);
    80003926:	00777693          	andi	a3,a4,7
    8000392a:	00d996bb          	sllw	a3,s3,a3
      if((bp->data[bi/8] & m) == 0){  // Is block free?
    8000392e:	41f7579b          	sraiw	a5,a4,0x1f
    80003932:	01d7d79b          	srliw	a5,a5,0x1d
    80003936:	9fb9                	addw	a5,a5,a4
    80003938:	4037d79b          	sraiw	a5,a5,0x3
    8000393c:	00f90633          	add	a2,s2,a5
    80003940:	05864603          	lbu	a2,88(a2) # 1058 <_entry-0x7fffefa8>
    80003944:	00c6f5b3          	and	a1,a3,a2
    80003948:	d585                	beqz	a1,80003870 <balloc+0x3a>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    8000394a:	2705                	addiw	a4,a4,1
    8000394c:	2485                	addiw	s1,s1,1
    8000394e:	fd471ae3          	bne	a4,s4,80003922 <balloc+0xec>
    80003952:	b769                	j	800038dc <balloc+0xa6>
  printf("balloc: out of blocks\n");
    80003954:	00005517          	auipc	a0,0x5
    80003958:	c1c50513          	addi	a0,a0,-996 # 80008570 <syscalls+0x120>
    8000395c:	ffffd097          	auipc	ra,0xffffd
    80003960:	c2e080e7          	jalr	-978(ra) # 8000058a <printf>
  return 0;
    80003964:	4481                	li	s1,0
    80003966:	bfa9                	j	800038c0 <balloc+0x8a>

0000000080003968 <bmap>:
// Return the disk block address of the nth block in inode ip.
// If there is no such block, bmap allocates one.
// returns 0 if out of disk space.
static uint
bmap(struct inode *ip, uint bn)
{
    80003968:	7179                	addi	sp,sp,-48
    8000396a:	f406                	sd	ra,40(sp)
    8000396c:	f022                	sd	s0,32(sp)
    8000396e:	ec26                	sd	s1,24(sp)
    80003970:	e84a                	sd	s2,16(sp)
    80003972:	e44e                	sd	s3,8(sp)
    80003974:	e052                	sd	s4,0(sp)
    80003976:	1800                	addi	s0,sp,48
    80003978:	89aa                	mv	s3,a0
  uint addr, *a;
  struct buf *bp;

  if(bn < NDIRECT){
    8000397a:	47ad                	li	a5,11
    8000397c:	02b7e863          	bltu	a5,a1,800039ac <bmap+0x44>
    if((addr = ip->addrs[bn]) == 0){
    80003980:	02059793          	slli	a5,a1,0x20
    80003984:	01e7d593          	srli	a1,a5,0x1e
    80003988:	00b504b3          	add	s1,a0,a1
    8000398c:	0504a903          	lw	s2,80(s1)
    80003990:	06091e63          	bnez	s2,80003a0c <bmap+0xa4>
      addr = balloc(ip->dev);
    80003994:	4108                	lw	a0,0(a0)
    80003996:	00000097          	auipc	ra,0x0
    8000399a:	ea0080e7          	jalr	-352(ra) # 80003836 <balloc>
    8000399e:	0005091b          	sext.w	s2,a0
      if(addr == 0)
    800039a2:	06090563          	beqz	s2,80003a0c <bmap+0xa4>
        return 0;
      ip->addrs[bn] = addr;
    800039a6:	0524a823          	sw	s2,80(s1)
    800039aa:	a08d                	j	80003a0c <bmap+0xa4>
    }
    return addr;
  }
  bn -= NDIRECT;
    800039ac:	ff45849b          	addiw	s1,a1,-12
    800039b0:	0004871b          	sext.w	a4,s1

  if(bn < NINDIRECT){
    800039b4:	0ff00793          	li	a5,255
    800039b8:	08e7e563          	bltu	a5,a4,80003a42 <bmap+0xda>
    // Load indirect block, allocating if necessary.
    if((addr = ip->addrs[NDIRECT]) == 0){
    800039bc:	08052903          	lw	s2,128(a0)
    800039c0:	00091d63          	bnez	s2,800039da <bmap+0x72>
      addr = balloc(ip->dev);
    800039c4:	4108                	lw	a0,0(a0)
    800039c6:	00000097          	auipc	ra,0x0
    800039ca:	e70080e7          	jalr	-400(ra) # 80003836 <balloc>
    800039ce:	0005091b          	sext.w	s2,a0
      if(addr == 0)
    800039d2:	02090d63          	beqz	s2,80003a0c <bmap+0xa4>
        return 0;
      ip->addrs[NDIRECT] = addr;
    800039d6:	0929a023          	sw	s2,128(s3)
    }
    bp = bread(ip->dev, addr);
    800039da:	85ca                	mv	a1,s2
    800039dc:	0009a503          	lw	a0,0(s3)
    800039e0:	00000097          	auipc	ra,0x0
    800039e4:	b94080e7          	jalr	-1132(ra) # 80003574 <bread>
    800039e8:	8a2a                	mv	s4,a0
    a = (uint*)bp->data;
    800039ea:	05850793          	addi	a5,a0,88
    if((addr = a[bn]) == 0){
    800039ee:	02049713          	slli	a4,s1,0x20
    800039f2:	01e75593          	srli	a1,a4,0x1e
    800039f6:	00b784b3          	add	s1,a5,a1
    800039fa:	0004a903          	lw	s2,0(s1)
    800039fe:	02090063          	beqz	s2,80003a1e <bmap+0xb6>
      if(addr){
        a[bn] = addr;
        log_write(bp);
      }
    }
    brelse(bp);
    80003a02:	8552                	mv	a0,s4
    80003a04:	00000097          	auipc	ra,0x0
    80003a08:	ca0080e7          	jalr	-864(ra) # 800036a4 <brelse>
    return addr;
  }

  panic("bmap: out of range");
}
    80003a0c:	854a                	mv	a0,s2
    80003a0e:	70a2                	ld	ra,40(sp)
    80003a10:	7402                	ld	s0,32(sp)
    80003a12:	64e2                	ld	s1,24(sp)
    80003a14:	6942                	ld	s2,16(sp)
    80003a16:	69a2                	ld	s3,8(sp)
    80003a18:	6a02                	ld	s4,0(sp)
    80003a1a:	6145                	addi	sp,sp,48
    80003a1c:	8082                	ret
      addr = balloc(ip->dev);
    80003a1e:	0009a503          	lw	a0,0(s3)
    80003a22:	00000097          	auipc	ra,0x0
    80003a26:	e14080e7          	jalr	-492(ra) # 80003836 <balloc>
    80003a2a:	0005091b          	sext.w	s2,a0
      if(addr){
    80003a2e:	fc090ae3          	beqz	s2,80003a02 <bmap+0x9a>
        a[bn] = addr;
    80003a32:	0124a023          	sw	s2,0(s1)
        log_write(bp);
    80003a36:	8552                	mv	a0,s4
    80003a38:	00001097          	auipc	ra,0x1
    80003a3c:	ef6080e7          	jalr	-266(ra) # 8000492e <log_write>
    80003a40:	b7c9                	j	80003a02 <bmap+0x9a>
  panic("bmap: out of range");
    80003a42:	00005517          	auipc	a0,0x5
    80003a46:	b4650513          	addi	a0,a0,-1210 # 80008588 <syscalls+0x138>
    80003a4a:	ffffd097          	auipc	ra,0xffffd
    80003a4e:	af6080e7          	jalr	-1290(ra) # 80000540 <panic>

0000000080003a52 <iget>:
{
    80003a52:	7179                	addi	sp,sp,-48
    80003a54:	f406                	sd	ra,40(sp)
    80003a56:	f022                	sd	s0,32(sp)
    80003a58:	ec26                	sd	s1,24(sp)
    80003a5a:	e84a                	sd	s2,16(sp)
    80003a5c:	e44e                	sd	s3,8(sp)
    80003a5e:	e052                	sd	s4,0(sp)
    80003a60:	1800                	addi	s0,sp,48
    80003a62:	89aa                	mv	s3,a0
    80003a64:	8a2e                	mv	s4,a1
  acquire(&itable.lock);
    80003a66:	0001c517          	auipc	a0,0x1c
    80003a6a:	43250513          	addi	a0,a0,1074 # 8001fe98 <itable>
    80003a6e:	ffffd097          	auipc	ra,0xffffd
    80003a72:	168080e7          	jalr	360(ra) # 80000bd6 <acquire>
  empty = 0;
    80003a76:	4901                	li	s2,0
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    80003a78:	0001c497          	auipc	s1,0x1c
    80003a7c:	43848493          	addi	s1,s1,1080 # 8001feb0 <itable+0x18>
    80003a80:	0001e697          	auipc	a3,0x1e
    80003a84:	ec068693          	addi	a3,a3,-320 # 80021940 <log>
    80003a88:	a039                	j	80003a96 <iget+0x44>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    80003a8a:	02090b63          	beqz	s2,80003ac0 <iget+0x6e>
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    80003a8e:	08848493          	addi	s1,s1,136
    80003a92:	02d48a63          	beq	s1,a3,80003ac6 <iget+0x74>
    if(ip->ref > 0 && ip->dev == dev && ip->inum == inum){
    80003a96:	449c                	lw	a5,8(s1)
    80003a98:	fef059e3          	blez	a5,80003a8a <iget+0x38>
    80003a9c:	4098                	lw	a4,0(s1)
    80003a9e:	ff3716e3          	bne	a4,s3,80003a8a <iget+0x38>
    80003aa2:	40d8                	lw	a4,4(s1)
    80003aa4:	ff4713e3          	bne	a4,s4,80003a8a <iget+0x38>
      ip->ref++;
    80003aa8:	2785                	addiw	a5,a5,1
    80003aaa:	c49c                	sw	a5,8(s1)
      release(&itable.lock);
    80003aac:	0001c517          	auipc	a0,0x1c
    80003ab0:	3ec50513          	addi	a0,a0,1004 # 8001fe98 <itable>
    80003ab4:	ffffd097          	auipc	ra,0xffffd
    80003ab8:	1d6080e7          	jalr	470(ra) # 80000c8a <release>
      return ip;
    80003abc:	8926                	mv	s2,s1
    80003abe:	a03d                	j	80003aec <iget+0x9a>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    80003ac0:	f7f9                	bnez	a5,80003a8e <iget+0x3c>
    80003ac2:	8926                	mv	s2,s1
    80003ac4:	b7e9                	j	80003a8e <iget+0x3c>
  if(empty == 0)
    80003ac6:	02090c63          	beqz	s2,80003afe <iget+0xac>
  ip->dev = dev;
    80003aca:	01392023          	sw	s3,0(s2)
  ip->inum = inum;
    80003ace:	01492223          	sw	s4,4(s2)
  ip->ref = 1;
    80003ad2:	4785                	li	a5,1
    80003ad4:	00f92423          	sw	a5,8(s2)
  ip->valid = 0;
    80003ad8:	04092023          	sw	zero,64(s2)
  release(&itable.lock);
    80003adc:	0001c517          	auipc	a0,0x1c
    80003ae0:	3bc50513          	addi	a0,a0,956 # 8001fe98 <itable>
    80003ae4:	ffffd097          	auipc	ra,0xffffd
    80003ae8:	1a6080e7          	jalr	422(ra) # 80000c8a <release>
}
    80003aec:	854a                	mv	a0,s2
    80003aee:	70a2                	ld	ra,40(sp)
    80003af0:	7402                	ld	s0,32(sp)
    80003af2:	64e2                	ld	s1,24(sp)
    80003af4:	6942                	ld	s2,16(sp)
    80003af6:	69a2                	ld	s3,8(sp)
    80003af8:	6a02                	ld	s4,0(sp)
    80003afa:	6145                	addi	sp,sp,48
    80003afc:	8082                	ret
    panic("iget: no inodes");
    80003afe:	00005517          	auipc	a0,0x5
    80003b02:	aa250513          	addi	a0,a0,-1374 # 800085a0 <syscalls+0x150>
    80003b06:	ffffd097          	auipc	ra,0xffffd
    80003b0a:	a3a080e7          	jalr	-1478(ra) # 80000540 <panic>

0000000080003b0e <fsinit>:
fsinit(int dev) {
    80003b0e:	7179                	addi	sp,sp,-48
    80003b10:	f406                	sd	ra,40(sp)
    80003b12:	f022                	sd	s0,32(sp)
    80003b14:	ec26                	sd	s1,24(sp)
    80003b16:	e84a                	sd	s2,16(sp)
    80003b18:	e44e                	sd	s3,8(sp)
    80003b1a:	1800                	addi	s0,sp,48
    80003b1c:	892a                	mv	s2,a0
  bp = bread(dev, 1);
    80003b1e:	4585                	li	a1,1
    80003b20:	00000097          	auipc	ra,0x0
    80003b24:	a54080e7          	jalr	-1452(ra) # 80003574 <bread>
    80003b28:	84aa                	mv	s1,a0
  memmove(sb, bp->data, sizeof(*sb));
    80003b2a:	0001c997          	auipc	s3,0x1c
    80003b2e:	34e98993          	addi	s3,s3,846 # 8001fe78 <sb>
    80003b32:	02000613          	li	a2,32
    80003b36:	05850593          	addi	a1,a0,88
    80003b3a:	854e                	mv	a0,s3
    80003b3c:	ffffd097          	auipc	ra,0xffffd
    80003b40:	1f2080e7          	jalr	498(ra) # 80000d2e <memmove>
  brelse(bp);
    80003b44:	8526                	mv	a0,s1
    80003b46:	00000097          	auipc	ra,0x0
    80003b4a:	b5e080e7          	jalr	-1186(ra) # 800036a4 <brelse>
  if(sb.magic != FSMAGIC)
    80003b4e:	0009a703          	lw	a4,0(s3)
    80003b52:	102037b7          	lui	a5,0x10203
    80003b56:	04078793          	addi	a5,a5,64 # 10203040 <_entry-0x6fdfcfc0>
    80003b5a:	02f71263          	bne	a4,a5,80003b7e <fsinit+0x70>
  initlog(dev, &sb);
    80003b5e:	0001c597          	auipc	a1,0x1c
    80003b62:	31a58593          	addi	a1,a1,794 # 8001fe78 <sb>
    80003b66:	854a                	mv	a0,s2
    80003b68:	00001097          	auipc	ra,0x1
    80003b6c:	b4a080e7          	jalr	-1206(ra) # 800046b2 <initlog>
}
    80003b70:	70a2                	ld	ra,40(sp)
    80003b72:	7402                	ld	s0,32(sp)
    80003b74:	64e2                	ld	s1,24(sp)
    80003b76:	6942                	ld	s2,16(sp)
    80003b78:	69a2                	ld	s3,8(sp)
    80003b7a:	6145                	addi	sp,sp,48
    80003b7c:	8082                	ret
    panic("invalid file system");
    80003b7e:	00005517          	auipc	a0,0x5
    80003b82:	a3250513          	addi	a0,a0,-1486 # 800085b0 <syscalls+0x160>
    80003b86:	ffffd097          	auipc	ra,0xffffd
    80003b8a:	9ba080e7          	jalr	-1606(ra) # 80000540 <panic>

0000000080003b8e <iinit>:
{
    80003b8e:	7179                	addi	sp,sp,-48
    80003b90:	f406                	sd	ra,40(sp)
    80003b92:	f022                	sd	s0,32(sp)
    80003b94:	ec26                	sd	s1,24(sp)
    80003b96:	e84a                	sd	s2,16(sp)
    80003b98:	e44e                	sd	s3,8(sp)
    80003b9a:	1800                	addi	s0,sp,48
  initlock(&itable.lock, "itable");
    80003b9c:	00005597          	auipc	a1,0x5
    80003ba0:	a2c58593          	addi	a1,a1,-1492 # 800085c8 <syscalls+0x178>
    80003ba4:	0001c517          	auipc	a0,0x1c
    80003ba8:	2f450513          	addi	a0,a0,756 # 8001fe98 <itable>
    80003bac:	ffffd097          	auipc	ra,0xffffd
    80003bb0:	f9a080e7          	jalr	-102(ra) # 80000b46 <initlock>
  for(i = 0; i < NINODE; i++) {
    80003bb4:	0001c497          	auipc	s1,0x1c
    80003bb8:	30c48493          	addi	s1,s1,780 # 8001fec0 <itable+0x28>
    80003bbc:	0001e997          	auipc	s3,0x1e
    80003bc0:	d9498993          	addi	s3,s3,-620 # 80021950 <log+0x10>
    initsleeplock(&itable.inode[i].lock, "inode");
    80003bc4:	00005917          	auipc	s2,0x5
    80003bc8:	a0c90913          	addi	s2,s2,-1524 # 800085d0 <syscalls+0x180>
    80003bcc:	85ca                	mv	a1,s2
    80003bce:	8526                	mv	a0,s1
    80003bd0:	00001097          	auipc	ra,0x1
    80003bd4:	e42080e7          	jalr	-446(ra) # 80004a12 <initsleeplock>
  for(i = 0; i < NINODE; i++) {
    80003bd8:	08848493          	addi	s1,s1,136
    80003bdc:	ff3498e3          	bne	s1,s3,80003bcc <iinit+0x3e>
}
    80003be0:	70a2                	ld	ra,40(sp)
    80003be2:	7402                	ld	s0,32(sp)
    80003be4:	64e2                	ld	s1,24(sp)
    80003be6:	6942                	ld	s2,16(sp)
    80003be8:	69a2                	ld	s3,8(sp)
    80003bea:	6145                	addi	sp,sp,48
    80003bec:	8082                	ret

0000000080003bee <ialloc>:
{
    80003bee:	715d                	addi	sp,sp,-80
    80003bf0:	e486                	sd	ra,72(sp)
    80003bf2:	e0a2                	sd	s0,64(sp)
    80003bf4:	fc26                	sd	s1,56(sp)
    80003bf6:	f84a                	sd	s2,48(sp)
    80003bf8:	f44e                	sd	s3,40(sp)
    80003bfa:	f052                	sd	s4,32(sp)
    80003bfc:	ec56                	sd	s5,24(sp)
    80003bfe:	e85a                	sd	s6,16(sp)
    80003c00:	e45e                	sd	s7,8(sp)
    80003c02:	0880                	addi	s0,sp,80
  for(inum = 1; inum < sb.ninodes; inum++){
    80003c04:	0001c717          	auipc	a4,0x1c
    80003c08:	28072703          	lw	a4,640(a4) # 8001fe84 <sb+0xc>
    80003c0c:	4785                	li	a5,1
    80003c0e:	04e7fa63          	bgeu	a5,a4,80003c62 <ialloc+0x74>
    80003c12:	8aaa                	mv	s5,a0
    80003c14:	8bae                	mv	s7,a1
    80003c16:	4485                	li	s1,1
    bp = bread(dev, IBLOCK(inum, sb));
    80003c18:	0001ca17          	auipc	s4,0x1c
    80003c1c:	260a0a13          	addi	s4,s4,608 # 8001fe78 <sb>
    80003c20:	00048b1b          	sext.w	s6,s1
    80003c24:	0044d593          	srli	a1,s1,0x4
    80003c28:	018a2783          	lw	a5,24(s4)
    80003c2c:	9dbd                	addw	a1,a1,a5
    80003c2e:	8556                	mv	a0,s5
    80003c30:	00000097          	auipc	ra,0x0
    80003c34:	944080e7          	jalr	-1724(ra) # 80003574 <bread>
    80003c38:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + inum%IPB;
    80003c3a:	05850993          	addi	s3,a0,88
    80003c3e:	00f4f793          	andi	a5,s1,15
    80003c42:	079a                	slli	a5,a5,0x6
    80003c44:	99be                	add	s3,s3,a5
    if(dip->type == 0){  // a free inode
    80003c46:	00099783          	lh	a5,0(s3)
    80003c4a:	c3a1                	beqz	a5,80003c8a <ialloc+0x9c>
    brelse(bp);
    80003c4c:	00000097          	auipc	ra,0x0
    80003c50:	a58080e7          	jalr	-1448(ra) # 800036a4 <brelse>
  for(inum = 1; inum < sb.ninodes; inum++){
    80003c54:	0485                	addi	s1,s1,1
    80003c56:	00ca2703          	lw	a4,12(s4)
    80003c5a:	0004879b          	sext.w	a5,s1
    80003c5e:	fce7e1e3          	bltu	a5,a4,80003c20 <ialloc+0x32>
  printf("ialloc: no inodes\n");
    80003c62:	00005517          	auipc	a0,0x5
    80003c66:	97650513          	addi	a0,a0,-1674 # 800085d8 <syscalls+0x188>
    80003c6a:	ffffd097          	auipc	ra,0xffffd
    80003c6e:	920080e7          	jalr	-1760(ra) # 8000058a <printf>
  return 0;
    80003c72:	4501                	li	a0,0
}
    80003c74:	60a6                	ld	ra,72(sp)
    80003c76:	6406                	ld	s0,64(sp)
    80003c78:	74e2                	ld	s1,56(sp)
    80003c7a:	7942                	ld	s2,48(sp)
    80003c7c:	79a2                	ld	s3,40(sp)
    80003c7e:	7a02                	ld	s4,32(sp)
    80003c80:	6ae2                	ld	s5,24(sp)
    80003c82:	6b42                	ld	s6,16(sp)
    80003c84:	6ba2                	ld	s7,8(sp)
    80003c86:	6161                	addi	sp,sp,80
    80003c88:	8082                	ret
      memset(dip, 0, sizeof(*dip));
    80003c8a:	04000613          	li	a2,64
    80003c8e:	4581                	li	a1,0
    80003c90:	854e                	mv	a0,s3
    80003c92:	ffffd097          	auipc	ra,0xffffd
    80003c96:	040080e7          	jalr	64(ra) # 80000cd2 <memset>
      dip->type = type;
    80003c9a:	01799023          	sh	s7,0(s3)
      log_write(bp);   // mark it allocated on the disk
    80003c9e:	854a                	mv	a0,s2
    80003ca0:	00001097          	auipc	ra,0x1
    80003ca4:	c8e080e7          	jalr	-882(ra) # 8000492e <log_write>
      brelse(bp);
    80003ca8:	854a                	mv	a0,s2
    80003caa:	00000097          	auipc	ra,0x0
    80003cae:	9fa080e7          	jalr	-1542(ra) # 800036a4 <brelse>
      return iget(dev, inum);
    80003cb2:	85da                	mv	a1,s6
    80003cb4:	8556                	mv	a0,s5
    80003cb6:	00000097          	auipc	ra,0x0
    80003cba:	d9c080e7          	jalr	-612(ra) # 80003a52 <iget>
    80003cbe:	bf5d                	j	80003c74 <ialloc+0x86>

0000000080003cc0 <iupdate>:
{
    80003cc0:	1101                	addi	sp,sp,-32
    80003cc2:	ec06                	sd	ra,24(sp)
    80003cc4:	e822                	sd	s0,16(sp)
    80003cc6:	e426                	sd	s1,8(sp)
    80003cc8:	e04a                	sd	s2,0(sp)
    80003cca:	1000                	addi	s0,sp,32
    80003ccc:	84aa                	mv	s1,a0
  bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80003cce:	415c                	lw	a5,4(a0)
    80003cd0:	0047d79b          	srliw	a5,a5,0x4
    80003cd4:	0001c597          	auipc	a1,0x1c
    80003cd8:	1bc5a583          	lw	a1,444(a1) # 8001fe90 <sb+0x18>
    80003cdc:	9dbd                	addw	a1,a1,a5
    80003cde:	4108                	lw	a0,0(a0)
    80003ce0:	00000097          	auipc	ra,0x0
    80003ce4:	894080e7          	jalr	-1900(ra) # 80003574 <bread>
    80003ce8:	892a                	mv	s2,a0
  dip = (struct dinode*)bp->data + ip->inum%IPB;
    80003cea:	05850793          	addi	a5,a0,88
    80003cee:	40d8                	lw	a4,4(s1)
    80003cf0:	8b3d                	andi	a4,a4,15
    80003cf2:	071a                	slli	a4,a4,0x6
    80003cf4:	97ba                	add	a5,a5,a4
  dip->type = ip->type;
    80003cf6:	04449703          	lh	a4,68(s1)
    80003cfa:	00e79023          	sh	a4,0(a5)
  dip->major = ip->major;
    80003cfe:	04649703          	lh	a4,70(s1)
    80003d02:	00e79123          	sh	a4,2(a5)
  dip->minor = ip->minor;
    80003d06:	04849703          	lh	a4,72(s1)
    80003d0a:	00e79223          	sh	a4,4(a5)
  dip->nlink = ip->nlink;
    80003d0e:	04a49703          	lh	a4,74(s1)
    80003d12:	00e79323          	sh	a4,6(a5)
  dip->size = ip->size;
    80003d16:	44f8                	lw	a4,76(s1)
    80003d18:	c798                	sw	a4,8(a5)
  memmove(dip->addrs, ip->addrs, sizeof(ip->addrs));
    80003d1a:	03400613          	li	a2,52
    80003d1e:	05048593          	addi	a1,s1,80
    80003d22:	00c78513          	addi	a0,a5,12
    80003d26:	ffffd097          	auipc	ra,0xffffd
    80003d2a:	008080e7          	jalr	8(ra) # 80000d2e <memmove>
  log_write(bp);
    80003d2e:	854a                	mv	a0,s2
    80003d30:	00001097          	auipc	ra,0x1
    80003d34:	bfe080e7          	jalr	-1026(ra) # 8000492e <log_write>
  brelse(bp);
    80003d38:	854a                	mv	a0,s2
    80003d3a:	00000097          	auipc	ra,0x0
    80003d3e:	96a080e7          	jalr	-1686(ra) # 800036a4 <brelse>
}
    80003d42:	60e2                	ld	ra,24(sp)
    80003d44:	6442                	ld	s0,16(sp)
    80003d46:	64a2                	ld	s1,8(sp)
    80003d48:	6902                	ld	s2,0(sp)
    80003d4a:	6105                	addi	sp,sp,32
    80003d4c:	8082                	ret

0000000080003d4e <idup>:
{
    80003d4e:	1101                	addi	sp,sp,-32
    80003d50:	ec06                	sd	ra,24(sp)
    80003d52:	e822                	sd	s0,16(sp)
    80003d54:	e426                	sd	s1,8(sp)
    80003d56:	1000                	addi	s0,sp,32
    80003d58:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    80003d5a:	0001c517          	auipc	a0,0x1c
    80003d5e:	13e50513          	addi	a0,a0,318 # 8001fe98 <itable>
    80003d62:	ffffd097          	auipc	ra,0xffffd
    80003d66:	e74080e7          	jalr	-396(ra) # 80000bd6 <acquire>
  ip->ref++;
    80003d6a:	449c                	lw	a5,8(s1)
    80003d6c:	2785                	addiw	a5,a5,1
    80003d6e:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    80003d70:	0001c517          	auipc	a0,0x1c
    80003d74:	12850513          	addi	a0,a0,296 # 8001fe98 <itable>
    80003d78:	ffffd097          	auipc	ra,0xffffd
    80003d7c:	f12080e7          	jalr	-238(ra) # 80000c8a <release>
}
    80003d80:	8526                	mv	a0,s1
    80003d82:	60e2                	ld	ra,24(sp)
    80003d84:	6442                	ld	s0,16(sp)
    80003d86:	64a2                	ld	s1,8(sp)
    80003d88:	6105                	addi	sp,sp,32
    80003d8a:	8082                	ret

0000000080003d8c <ilock>:
{
    80003d8c:	1101                	addi	sp,sp,-32
    80003d8e:	ec06                	sd	ra,24(sp)
    80003d90:	e822                	sd	s0,16(sp)
    80003d92:	e426                	sd	s1,8(sp)
    80003d94:	e04a                	sd	s2,0(sp)
    80003d96:	1000                	addi	s0,sp,32
  if(ip == 0 || ip->ref < 1)
    80003d98:	c115                	beqz	a0,80003dbc <ilock+0x30>
    80003d9a:	84aa                	mv	s1,a0
    80003d9c:	451c                	lw	a5,8(a0)
    80003d9e:	00f05f63          	blez	a5,80003dbc <ilock+0x30>
  acquiresleep(&ip->lock);
    80003da2:	0541                	addi	a0,a0,16
    80003da4:	00001097          	auipc	ra,0x1
    80003da8:	ca8080e7          	jalr	-856(ra) # 80004a4c <acquiresleep>
  if(ip->valid == 0){
    80003dac:	40bc                	lw	a5,64(s1)
    80003dae:	cf99                	beqz	a5,80003dcc <ilock+0x40>
}
    80003db0:	60e2                	ld	ra,24(sp)
    80003db2:	6442                	ld	s0,16(sp)
    80003db4:	64a2                	ld	s1,8(sp)
    80003db6:	6902                	ld	s2,0(sp)
    80003db8:	6105                	addi	sp,sp,32
    80003dba:	8082                	ret
    panic("ilock");
    80003dbc:	00005517          	auipc	a0,0x5
    80003dc0:	83450513          	addi	a0,a0,-1996 # 800085f0 <syscalls+0x1a0>
    80003dc4:	ffffc097          	auipc	ra,0xffffc
    80003dc8:	77c080e7          	jalr	1916(ra) # 80000540 <panic>
    bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80003dcc:	40dc                	lw	a5,4(s1)
    80003dce:	0047d79b          	srliw	a5,a5,0x4
    80003dd2:	0001c597          	auipc	a1,0x1c
    80003dd6:	0be5a583          	lw	a1,190(a1) # 8001fe90 <sb+0x18>
    80003dda:	9dbd                	addw	a1,a1,a5
    80003ddc:	4088                	lw	a0,0(s1)
    80003dde:	fffff097          	auipc	ra,0xfffff
    80003de2:	796080e7          	jalr	1942(ra) # 80003574 <bread>
    80003de6:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + ip->inum%IPB;
    80003de8:	05850593          	addi	a1,a0,88
    80003dec:	40dc                	lw	a5,4(s1)
    80003dee:	8bbd                	andi	a5,a5,15
    80003df0:	079a                	slli	a5,a5,0x6
    80003df2:	95be                	add	a1,a1,a5
    ip->type = dip->type;
    80003df4:	00059783          	lh	a5,0(a1)
    80003df8:	04f49223          	sh	a5,68(s1)
    ip->major = dip->major;
    80003dfc:	00259783          	lh	a5,2(a1)
    80003e00:	04f49323          	sh	a5,70(s1)
    ip->minor = dip->minor;
    80003e04:	00459783          	lh	a5,4(a1)
    80003e08:	04f49423          	sh	a5,72(s1)
    ip->nlink = dip->nlink;
    80003e0c:	00659783          	lh	a5,6(a1)
    80003e10:	04f49523          	sh	a5,74(s1)
    ip->size = dip->size;
    80003e14:	459c                	lw	a5,8(a1)
    80003e16:	c4fc                	sw	a5,76(s1)
    memmove(ip->addrs, dip->addrs, sizeof(ip->addrs));
    80003e18:	03400613          	li	a2,52
    80003e1c:	05b1                	addi	a1,a1,12
    80003e1e:	05048513          	addi	a0,s1,80
    80003e22:	ffffd097          	auipc	ra,0xffffd
    80003e26:	f0c080e7          	jalr	-244(ra) # 80000d2e <memmove>
    brelse(bp);
    80003e2a:	854a                	mv	a0,s2
    80003e2c:	00000097          	auipc	ra,0x0
    80003e30:	878080e7          	jalr	-1928(ra) # 800036a4 <brelse>
    ip->valid = 1;
    80003e34:	4785                	li	a5,1
    80003e36:	c0bc                	sw	a5,64(s1)
    if(ip->type == 0)
    80003e38:	04449783          	lh	a5,68(s1)
    80003e3c:	fbb5                	bnez	a5,80003db0 <ilock+0x24>
      panic("ilock: no type");
    80003e3e:	00004517          	auipc	a0,0x4
    80003e42:	7ba50513          	addi	a0,a0,1978 # 800085f8 <syscalls+0x1a8>
    80003e46:	ffffc097          	auipc	ra,0xffffc
    80003e4a:	6fa080e7          	jalr	1786(ra) # 80000540 <panic>

0000000080003e4e <iunlock>:
{
    80003e4e:	1101                	addi	sp,sp,-32
    80003e50:	ec06                	sd	ra,24(sp)
    80003e52:	e822                	sd	s0,16(sp)
    80003e54:	e426                	sd	s1,8(sp)
    80003e56:	e04a                	sd	s2,0(sp)
    80003e58:	1000                	addi	s0,sp,32
  if(ip == 0 || !holdingsleep(&ip->lock) || ip->ref < 1)
    80003e5a:	c905                	beqz	a0,80003e8a <iunlock+0x3c>
    80003e5c:	84aa                	mv	s1,a0
    80003e5e:	01050913          	addi	s2,a0,16
    80003e62:	854a                	mv	a0,s2
    80003e64:	00001097          	auipc	ra,0x1
    80003e68:	c82080e7          	jalr	-894(ra) # 80004ae6 <holdingsleep>
    80003e6c:	cd19                	beqz	a0,80003e8a <iunlock+0x3c>
    80003e6e:	449c                	lw	a5,8(s1)
    80003e70:	00f05d63          	blez	a5,80003e8a <iunlock+0x3c>
  releasesleep(&ip->lock);
    80003e74:	854a                	mv	a0,s2
    80003e76:	00001097          	auipc	ra,0x1
    80003e7a:	c2c080e7          	jalr	-980(ra) # 80004aa2 <releasesleep>
}
    80003e7e:	60e2                	ld	ra,24(sp)
    80003e80:	6442                	ld	s0,16(sp)
    80003e82:	64a2                	ld	s1,8(sp)
    80003e84:	6902                	ld	s2,0(sp)
    80003e86:	6105                	addi	sp,sp,32
    80003e88:	8082                	ret
    panic("iunlock");
    80003e8a:	00004517          	auipc	a0,0x4
    80003e8e:	77e50513          	addi	a0,a0,1918 # 80008608 <syscalls+0x1b8>
    80003e92:	ffffc097          	auipc	ra,0xffffc
    80003e96:	6ae080e7          	jalr	1710(ra) # 80000540 <panic>

0000000080003e9a <itrunc>:

// Truncate inode (discard contents).
// Caller must hold ip->lock.
void
itrunc(struct inode *ip)
{
    80003e9a:	7179                	addi	sp,sp,-48
    80003e9c:	f406                	sd	ra,40(sp)
    80003e9e:	f022                	sd	s0,32(sp)
    80003ea0:	ec26                	sd	s1,24(sp)
    80003ea2:	e84a                	sd	s2,16(sp)
    80003ea4:	e44e                	sd	s3,8(sp)
    80003ea6:	e052                	sd	s4,0(sp)
    80003ea8:	1800                	addi	s0,sp,48
    80003eaa:	89aa                	mv	s3,a0
  int i, j;
  struct buf *bp;
  uint *a;

  for(i = 0; i < NDIRECT; i++){
    80003eac:	05050493          	addi	s1,a0,80
    80003eb0:	08050913          	addi	s2,a0,128
    80003eb4:	a021                	j	80003ebc <itrunc+0x22>
    80003eb6:	0491                	addi	s1,s1,4
    80003eb8:	01248d63          	beq	s1,s2,80003ed2 <itrunc+0x38>
    if(ip->addrs[i]){
    80003ebc:	408c                	lw	a1,0(s1)
    80003ebe:	dde5                	beqz	a1,80003eb6 <itrunc+0x1c>
      bfree(ip->dev, ip->addrs[i]);
    80003ec0:	0009a503          	lw	a0,0(s3)
    80003ec4:	00000097          	auipc	ra,0x0
    80003ec8:	8f6080e7          	jalr	-1802(ra) # 800037ba <bfree>
      ip->addrs[i] = 0;
    80003ecc:	0004a023          	sw	zero,0(s1)
    80003ed0:	b7dd                	j	80003eb6 <itrunc+0x1c>
    }
  }

  if(ip->addrs[NDIRECT]){
    80003ed2:	0809a583          	lw	a1,128(s3)
    80003ed6:	e185                	bnez	a1,80003ef6 <itrunc+0x5c>
    brelse(bp);
    bfree(ip->dev, ip->addrs[NDIRECT]);
    ip->addrs[NDIRECT] = 0;
  }

  ip->size = 0;
    80003ed8:	0409a623          	sw	zero,76(s3)
  iupdate(ip);
    80003edc:	854e                	mv	a0,s3
    80003ede:	00000097          	auipc	ra,0x0
    80003ee2:	de2080e7          	jalr	-542(ra) # 80003cc0 <iupdate>
}
    80003ee6:	70a2                	ld	ra,40(sp)
    80003ee8:	7402                	ld	s0,32(sp)
    80003eea:	64e2                	ld	s1,24(sp)
    80003eec:	6942                	ld	s2,16(sp)
    80003eee:	69a2                	ld	s3,8(sp)
    80003ef0:	6a02                	ld	s4,0(sp)
    80003ef2:	6145                	addi	sp,sp,48
    80003ef4:	8082                	ret
    bp = bread(ip->dev, ip->addrs[NDIRECT]);
    80003ef6:	0009a503          	lw	a0,0(s3)
    80003efa:	fffff097          	auipc	ra,0xfffff
    80003efe:	67a080e7          	jalr	1658(ra) # 80003574 <bread>
    80003f02:	8a2a                	mv	s4,a0
    for(j = 0; j < NINDIRECT; j++){
    80003f04:	05850493          	addi	s1,a0,88
    80003f08:	45850913          	addi	s2,a0,1112
    80003f0c:	a021                	j	80003f14 <itrunc+0x7a>
    80003f0e:	0491                	addi	s1,s1,4
    80003f10:	01248b63          	beq	s1,s2,80003f26 <itrunc+0x8c>
      if(a[j])
    80003f14:	408c                	lw	a1,0(s1)
    80003f16:	dde5                	beqz	a1,80003f0e <itrunc+0x74>
        bfree(ip->dev, a[j]);
    80003f18:	0009a503          	lw	a0,0(s3)
    80003f1c:	00000097          	auipc	ra,0x0
    80003f20:	89e080e7          	jalr	-1890(ra) # 800037ba <bfree>
    80003f24:	b7ed                	j	80003f0e <itrunc+0x74>
    brelse(bp);
    80003f26:	8552                	mv	a0,s4
    80003f28:	fffff097          	auipc	ra,0xfffff
    80003f2c:	77c080e7          	jalr	1916(ra) # 800036a4 <brelse>
    bfree(ip->dev, ip->addrs[NDIRECT]);
    80003f30:	0809a583          	lw	a1,128(s3)
    80003f34:	0009a503          	lw	a0,0(s3)
    80003f38:	00000097          	auipc	ra,0x0
    80003f3c:	882080e7          	jalr	-1918(ra) # 800037ba <bfree>
    ip->addrs[NDIRECT] = 0;
    80003f40:	0809a023          	sw	zero,128(s3)
    80003f44:	bf51                	j	80003ed8 <itrunc+0x3e>

0000000080003f46 <iput>:
{
    80003f46:	1101                	addi	sp,sp,-32
    80003f48:	ec06                	sd	ra,24(sp)
    80003f4a:	e822                	sd	s0,16(sp)
    80003f4c:	e426                	sd	s1,8(sp)
    80003f4e:	e04a                	sd	s2,0(sp)
    80003f50:	1000                	addi	s0,sp,32
    80003f52:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    80003f54:	0001c517          	auipc	a0,0x1c
    80003f58:	f4450513          	addi	a0,a0,-188 # 8001fe98 <itable>
    80003f5c:	ffffd097          	auipc	ra,0xffffd
    80003f60:	c7a080e7          	jalr	-902(ra) # 80000bd6 <acquire>
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003f64:	4498                	lw	a4,8(s1)
    80003f66:	4785                	li	a5,1
    80003f68:	02f70363          	beq	a4,a5,80003f8e <iput+0x48>
  ip->ref--;
    80003f6c:	449c                	lw	a5,8(s1)
    80003f6e:	37fd                	addiw	a5,a5,-1
    80003f70:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    80003f72:	0001c517          	auipc	a0,0x1c
    80003f76:	f2650513          	addi	a0,a0,-218 # 8001fe98 <itable>
    80003f7a:	ffffd097          	auipc	ra,0xffffd
    80003f7e:	d10080e7          	jalr	-752(ra) # 80000c8a <release>
}
    80003f82:	60e2                	ld	ra,24(sp)
    80003f84:	6442                	ld	s0,16(sp)
    80003f86:	64a2                	ld	s1,8(sp)
    80003f88:	6902                	ld	s2,0(sp)
    80003f8a:	6105                	addi	sp,sp,32
    80003f8c:	8082                	ret
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003f8e:	40bc                	lw	a5,64(s1)
    80003f90:	dff1                	beqz	a5,80003f6c <iput+0x26>
    80003f92:	04a49783          	lh	a5,74(s1)
    80003f96:	fbf9                	bnez	a5,80003f6c <iput+0x26>
    acquiresleep(&ip->lock);
    80003f98:	01048913          	addi	s2,s1,16
    80003f9c:	854a                	mv	a0,s2
    80003f9e:	00001097          	auipc	ra,0x1
    80003fa2:	aae080e7          	jalr	-1362(ra) # 80004a4c <acquiresleep>
    release(&itable.lock);
    80003fa6:	0001c517          	auipc	a0,0x1c
    80003faa:	ef250513          	addi	a0,a0,-270 # 8001fe98 <itable>
    80003fae:	ffffd097          	auipc	ra,0xffffd
    80003fb2:	cdc080e7          	jalr	-804(ra) # 80000c8a <release>
    itrunc(ip);
    80003fb6:	8526                	mv	a0,s1
    80003fb8:	00000097          	auipc	ra,0x0
    80003fbc:	ee2080e7          	jalr	-286(ra) # 80003e9a <itrunc>
    ip->type = 0;
    80003fc0:	04049223          	sh	zero,68(s1)
    iupdate(ip);
    80003fc4:	8526                	mv	a0,s1
    80003fc6:	00000097          	auipc	ra,0x0
    80003fca:	cfa080e7          	jalr	-774(ra) # 80003cc0 <iupdate>
    ip->valid = 0;
    80003fce:	0404a023          	sw	zero,64(s1)
    releasesleep(&ip->lock);
    80003fd2:	854a                	mv	a0,s2
    80003fd4:	00001097          	auipc	ra,0x1
    80003fd8:	ace080e7          	jalr	-1330(ra) # 80004aa2 <releasesleep>
    acquire(&itable.lock);
    80003fdc:	0001c517          	auipc	a0,0x1c
    80003fe0:	ebc50513          	addi	a0,a0,-324 # 8001fe98 <itable>
    80003fe4:	ffffd097          	auipc	ra,0xffffd
    80003fe8:	bf2080e7          	jalr	-1038(ra) # 80000bd6 <acquire>
    80003fec:	b741                	j	80003f6c <iput+0x26>

0000000080003fee <iunlockput>:
{
    80003fee:	1101                	addi	sp,sp,-32
    80003ff0:	ec06                	sd	ra,24(sp)
    80003ff2:	e822                	sd	s0,16(sp)
    80003ff4:	e426                	sd	s1,8(sp)
    80003ff6:	1000                	addi	s0,sp,32
    80003ff8:	84aa                	mv	s1,a0
  iunlock(ip);
    80003ffa:	00000097          	auipc	ra,0x0
    80003ffe:	e54080e7          	jalr	-428(ra) # 80003e4e <iunlock>
  iput(ip);
    80004002:	8526                	mv	a0,s1
    80004004:	00000097          	auipc	ra,0x0
    80004008:	f42080e7          	jalr	-190(ra) # 80003f46 <iput>
}
    8000400c:	60e2                	ld	ra,24(sp)
    8000400e:	6442                	ld	s0,16(sp)
    80004010:	64a2                	ld	s1,8(sp)
    80004012:	6105                	addi	sp,sp,32
    80004014:	8082                	ret

0000000080004016 <stati>:

// Copy stat information from inode.
// Caller must hold ip->lock.
void
stati(struct inode *ip, struct stat *st)
{
    80004016:	1141                	addi	sp,sp,-16
    80004018:	e422                	sd	s0,8(sp)
    8000401a:	0800                	addi	s0,sp,16
  st->dev = ip->dev;
    8000401c:	411c                	lw	a5,0(a0)
    8000401e:	c19c                	sw	a5,0(a1)
  st->ino = ip->inum;
    80004020:	415c                	lw	a5,4(a0)
    80004022:	c1dc                	sw	a5,4(a1)
  st->type = ip->type;
    80004024:	04451783          	lh	a5,68(a0)
    80004028:	00f59423          	sh	a5,8(a1)
  st->nlink = ip->nlink;
    8000402c:	04a51783          	lh	a5,74(a0)
    80004030:	00f59523          	sh	a5,10(a1)
  st->size = ip->size;
    80004034:	04c56783          	lwu	a5,76(a0)
    80004038:	e99c                	sd	a5,16(a1)
}
    8000403a:	6422                	ld	s0,8(sp)
    8000403c:	0141                	addi	sp,sp,16
    8000403e:	8082                	ret

0000000080004040 <readi>:
readi(struct inode *ip, int user_dst, uint64 dst, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80004040:	457c                	lw	a5,76(a0)
    80004042:	0ed7e963          	bltu	a5,a3,80004134 <readi+0xf4>
{
    80004046:	7159                	addi	sp,sp,-112
    80004048:	f486                	sd	ra,104(sp)
    8000404a:	f0a2                	sd	s0,96(sp)
    8000404c:	eca6                	sd	s1,88(sp)
    8000404e:	e8ca                	sd	s2,80(sp)
    80004050:	e4ce                	sd	s3,72(sp)
    80004052:	e0d2                	sd	s4,64(sp)
    80004054:	fc56                	sd	s5,56(sp)
    80004056:	f85a                	sd	s6,48(sp)
    80004058:	f45e                	sd	s7,40(sp)
    8000405a:	f062                	sd	s8,32(sp)
    8000405c:	ec66                	sd	s9,24(sp)
    8000405e:	e86a                	sd	s10,16(sp)
    80004060:	e46e                	sd	s11,8(sp)
    80004062:	1880                	addi	s0,sp,112
    80004064:	8b2a                	mv	s6,a0
    80004066:	8bae                	mv	s7,a1
    80004068:	8a32                	mv	s4,a2
    8000406a:	84b6                	mv	s1,a3
    8000406c:	8aba                	mv	s5,a4
  if(off > ip->size || off + n < off)
    8000406e:	9f35                	addw	a4,a4,a3
    return 0;
    80004070:	4501                	li	a0,0
  if(off > ip->size || off + n < off)
    80004072:	0ad76063          	bltu	a4,a3,80004112 <readi+0xd2>
  if(off + n > ip->size)
    80004076:	00e7f463          	bgeu	a5,a4,8000407e <readi+0x3e>
    n = ip->size - off;
    8000407a:	40d78abb          	subw	s5,a5,a3

  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    8000407e:	0a0a8963          	beqz	s5,80004130 <readi+0xf0>
    80004082:	4981                	li	s3,0
    uint addr = bmap(ip, off/BSIZE);
    if(addr == 0)
      break;
    bp = bread(ip->dev, addr);
    m = min(n - tot, BSIZE - off%BSIZE);
    80004084:	40000c93          	li	s9,1024
    if(either_copyout(user_dst, dst, bp->data + (off % BSIZE), m) == -1) {
    80004088:	5c7d                	li	s8,-1
    8000408a:	a82d                	j	800040c4 <readi+0x84>
    8000408c:	020d1d93          	slli	s11,s10,0x20
    80004090:	020ddd93          	srli	s11,s11,0x20
    80004094:	05890613          	addi	a2,s2,88
    80004098:	86ee                	mv	a3,s11
    8000409a:	963a                	add	a2,a2,a4
    8000409c:	85d2                	mv	a1,s4
    8000409e:	855e                	mv	a0,s7
    800040a0:	ffffe097          	auipc	ra,0xffffe
    800040a4:	4ac080e7          	jalr	1196(ra) # 8000254c <either_copyout>
    800040a8:	05850d63          	beq	a0,s8,80004102 <readi+0xc2>
      brelse(bp);
      tot = -1;
      break;
    }
    brelse(bp);
    800040ac:	854a                	mv	a0,s2
    800040ae:	fffff097          	auipc	ra,0xfffff
    800040b2:	5f6080e7          	jalr	1526(ra) # 800036a4 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    800040b6:	013d09bb          	addw	s3,s10,s3
    800040ba:	009d04bb          	addw	s1,s10,s1
    800040be:	9a6e                	add	s4,s4,s11
    800040c0:	0559f763          	bgeu	s3,s5,8000410e <readi+0xce>
    uint addr = bmap(ip, off/BSIZE);
    800040c4:	00a4d59b          	srliw	a1,s1,0xa
    800040c8:	855a                	mv	a0,s6
    800040ca:	00000097          	auipc	ra,0x0
    800040ce:	89e080e7          	jalr	-1890(ra) # 80003968 <bmap>
    800040d2:	0005059b          	sext.w	a1,a0
    if(addr == 0)
    800040d6:	cd85                	beqz	a1,8000410e <readi+0xce>
    bp = bread(ip->dev, addr);
    800040d8:	000b2503          	lw	a0,0(s6)
    800040dc:	fffff097          	auipc	ra,0xfffff
    800040e0:	498080e7          	jalr	1176(ra) # 80003574 <bread>
    800040e4:	892a                	mv	s2,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    800040e6:	3ff4f713          	andi	a4,s1,1023
    800040ea:	40ec87bb          	subw	a5,s9,a4
    800040ee:	413a86bb          	subw	a3,s5,s3
    800040f2:	8d3e                	mv	s10,a5
    800040f4:	2781                	sext.w	a5,a5
    800040f6:	0006861b          	sext.w	a2,a3
    800040fa:	f8f679e3          	bgeu	a2,a5,8000408c <readi+0x4c>
    800040fe:	8d36                	mv	s10,a3
    80004100:	b771                	j	8000408c <readi+0x4c>
      brelse(bp);
    80004102:	854a                	mv	a0,s2
    80004104:	fffff097          	auipc	ra,0xfffff
    80004108:	5a0080e7          	jalr	1440(ra) # 800036a4 <brelse>
      tot = -1;
    8000410c:	59fd                	li	s3,-1
  }
  return tot;
    8000410e:	0009851b          	sext.w	a0,s3
}
    80004112:	70a6                	ld	ra,104(sp)
    80004114:	7406                	ld	s0,96(sp)
    80004116:	64e6                	ld	s1,88(sp)
    80004118:	6946                	ld	s2,80(sp)
    8000411a:	69a6                	ld	s3,72(sp)
    8000411c:	6a06                	ld	s4,64(sp)
    8000411e:	7ae2                	ld	s5,56(sp)
    80004120:	7b42                	ld	s6,48(sp)
    80004122:	7ba2                	ld	s7,40(sp)
    80004124:	7c02                	ld	s8,32(sp)
    80004126:	6ce2                	ld	s9,24(sp)
    80004128:	6d42                	ld	s10,16(sp)
    8000412a:	6da2                	ld	s11,8(sp)
    8000412c:	6165                	addi	sp,sp,112
    8000412e:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80004130:	89d6                	mv	s3,s5
    80004132:	bff1                	j	8000410e <readi+0xce>
    return 0;
    80004134:	4501                	li	a0,0
}
    80004136:	8082                	ret

0000000080004138 <writei>:
writei(struct inode *ip, int user_src, uint64 src, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80004138:	457c                	lw	a5,76(a0)
    8000413a:	10d7e863          	bltu	a5,a3,8000424a <writei+0x112>
{
    8000413e:	7159                	addi	sp,sp,-112
    80004140:	f486                	sd	ra,104(sp)
    80004142:	f0a2                	sd	s0,96(sp)
    80004144:	eca6                	sd	s1,88(sp)
    80004146:	e8ca                	sd	s2,80(sp)
    80004148:	e4ce                	sd	s3,72(sp)
    8000414a:	e0d2                	sd	s4,64(sp)
    8000414c:	fc56                	sd	s5,56(sp)
    8000414e:	f85a                	sd	s6,48(sp)
    80004150:	f45e                	sd	s7,40(sp)
    80004152:	f062                	sd	s8,32(sp)
    80004154:	ec66                	sd	s9,24(sp)
    80004156:	e86a                	sd	s10,16(sp)
    80004158:	e46e                	sd	s11,8(sp)
    8000415a:	1880                	addi	s0,sp,112
    8000415c:	8aaa                	mv	s5,a0
    8000415e:	8bae                	mv	s7,a1
    80004160:	8a32                	mv	s4,a2
    80004162:	8936                	mv	s2,a3
    80004164:	8b3a                	mv	s6,a4
  if(off > ip->size || off + n < off)
    80004166:	00e687bb          	addw	a5,a3,a4
    8000416a:	0ed7e263          	bltu	a5,a3,8000424e <writei+0x116>
    return -1;
  if(off + n > MAXFILE*BSIZE)
    8000416e:	00043737          	lui	a4,0x43
    80004172:	0ef76063          	bltu	a4,a5,80004252 <writei+0x11a>
    return -1;

  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80004176:	0c0b0863          	beqz	s6,80004246 <writei+0x10e>
    8000417a:	4981                	li	s3,0
    uint addr = bmap(ip, off/BSIZE);
    if(addr == 0)
      break;
    bp = bread(ip->dev, addr);
    m = min(n - tot, BSIZE - off%BSIZE);
    8000417c:	40000c93          	li	s9,1024
    if(either_copyin(bp->data + (off % BSIZE), user_src, src, m) == -1) {
    80004180:	5c7d                	li	s8,-1
    80004182:	a091                	j	800041c6 <writei+0x8e>
    80004184:	020d1d93          	slli	s11,s10,0x20
    80004188:	020ddd93          	srli	s11,s11,0x20
    8000418c:	05848513          	addi	a0,s1,88
    80004190:	86ee                	mv	a3,s11
    80004192:	8652                	mv	a2,s4
    80004194:	85de                	mv	a1,s7
    80004196:	953a                	add	a0,a0,a4
    80004198:	ffffe097          	auipc	ra,0xffffe
    8000419c:	40a080e7          	jalr	1034(ra) # 800025a2 <either_copyin>
    800041a0:	07850263          	beq	a0,s8,80004204 <writei+0xcc>
      brelse(bp);
      break;
    }
    log_write(bp);
    800041a4:	8526                	mv	a0,s1
    800041a6:	00000097          	auipc	ra,0x0
    800041aa:	788080e7          	jalr	1928(ra) # 8000492e <log_write>
    brelse(bp);
    800041ae:	8526                	mv	a0,s1
    800041b0:	fffff097          	auipc	ra,0xfffff
    800041b4:	4f4080e7          	jalr	1268(ra) # 800036a4 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    800041b8:	013d09bb          	addw	s3,s10,s3
    800041bc:	012d093b          	addw	s2,s10,s2
    800041c0:	9a6e                	add	s4,s4,s11
    800041c2:	0569f663          	bgeu	s3,s6,8000420e <writei+0xd6>
    uint addr = bmap(ip, off/BSIZE);
    800041c6:	00a9559b          	srliw	a1,s2,0xa
    800041ca:	8556                	mv	a0,s5
    800041cc:	fffff097          	auipc	ra,0xfffff
    800041d0:	79c080e7          	jalr	1948(ra) # 80003968 <bmap>
    800041d4:	0005059b          	sext.w	a1,a0
    if(addr == 0)
    800041d8:	c99d                	beqz	a1,8000420e <writei+0xd6>
    bp = bread(ip->dev, addr);
    800041da:	000aa503          	lw	a0,0(s5)
    800041de:	fffff097          	auipc	ra,0xfffff
    800041e2:	396080e7          	jalr	918(ra) # 80003574 <bread>
    800041e6:	84aa                	mv	s1,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    800041e8:	3ff97713          	andi	a4,s2,1023
    800041ec:	40ec87bb          	subw	a5,s9,a4
    800041f0:	413b06bb          	subw	a3,s6,s3
    800041f4:	8d3e                	mv	s10,a5
    800041f6:	2781                	sext.w	a5,a5
    800041f8:	0006861b          	sext.w	a2,a3
    800041fc:	f8f674e3          	bgeu	a2,a5,80004184 <writei+0x4c>
    80004200:	8d36                	mv	s10,a3
    80004202:	b749                	j	80004184 <writei+0x4c>
      brelse(bp);
    80004204:	8526                	mv	a0,s1
    80004206:	fffff097          	auipc	ra,0xfffff
    8000420a:	49e080e7          	jalr	1182(ra) # 800036a4 <brelse>
  }

  if(off > ip->size)
    8000420e:	04caa783          	lw	a5,76(s5)
    80004212:	0127f463          	bgeu	a5,s2,8000421a <writei+0xe2>
    ip->size = off;
    80004216:	052aa623          	sw	s2,76(s5)

  // write the i-node back to disk even if the size didn't change
  // because the loop above might have called bmap() and added a new
  // block to ip->addrs[].
  iupdate(ip);
    8000421a:	8556                	mv	a0,s5
    8000421c:	00000097          	auipc	ra,0x0
    80004220:	aa4080e7          	jalr	-1372(ra) # 80003cc0 <iupdate>

  return tot;
    80004224:	0009851b          	sext.w	a0,s3
}
    80004228:	70a6                	ld	ra,104(sp)
    8000422a:	7406                	ld	s0,96(sp)
    8000422c:	64e6                	ld	s1,88(sp)
    8000422e:	6946                	ld	s2,80(sp)
    80004230:	69a6                	ld	s3,72(sp)
    80004232:	6a06                	ld	s4,64(sp)
    80004234:	7ae2                	ld	s5,56(sp)
    80004236:	7b42                	ld	s6,48(sp)
    80004238:	7ba2                	ld	s7,40(sp)
    8000423a:	7c02                	ld	s8,32(sp)
    8000423c:	6ce2                	ld	s9,24(sp)
    8000423e:	6d42                	ld	s10,16(sp)
    80004240:	6da2                	ld	s11,8(sp)
    80004242:	6165                	addi	sp,sp,112
    80004244:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80004246:	89da                	mv	s3,s6
    80004248:	bfc9                	j	8000421a <writei+0xe2>
    return -1;
    8000424a:	557d                	li	a0,-1
}
    8000424c:	8082                	ret
    return -1;
    8000424e:	557d                	li	a0,-1
    80004250:	bfe1                	j	80004228 <writei+0xf0>
    return -1;
    80004252:	557d                	li	a0,-1
    80004254:	bfd1                	j	80004228 <writei+0xf0>

0000000080004256 <namecmp>:

// Directories

int
namecmp(const char *s, const char *t)
{
    80004256:	1141                	addi	sp,sp,-16
    80004258:	e406                	sd	ra,8(sp)
    8000425a:	e022                	sd	s0,0(sp)
    8000425c:	0800                	addi	s0,sp,16
  return strncmp(s, t, DIRSIZ);
    8000425e:	4639                	li	a2,14
    80004260:	ffffd097          	auipc	ra,0xffffd
    80004264:	b42080e7          	jalr	-1214(ra) # 80000da2 <strncmp>
}
    80004268:	60a2                	ld	ra,8(sp)
    8000426a:	6402                	ld	s0,0(sp)
    8000426c:	0141                	addi	sp,sp,16
    8000426e:	8082                	ret

0000000080004270 <dirlookup>:

// Look for a directory entry in a directory.
// If found, set *poff to byte offset of entry.
struct inode*
dirlookup(struct inode *dp, char *name, uint *poff)
{
    80004270:	7139                	addi	sp,sp,-64
    80004272:	fc06                	sd	ra,56(sp)
    80004274:	f822                	sd	s0,48(sp)
    80004276:	f426                	sd	s1,40(sp)
    80004278:	f04a                	sd	s2,32(sp)
    8000427a:	ec4e                	sd	s3,24(sp)
    8000427c:	e852                	sd	s4,16(sp)
    8000427e:	0080                	addi	s0,sp,64
  uint off, inum;
  struct dirent de;

  if(dp->type != T_DIR)
    80004280:	04451703          	lh	a4,68(a0)
    80004284:	4785                	li	a5,1
    80004286:	00f71a63          	bne	a4,a5,8000429a <dirlookup+0x2a>
    8000428a:	892a                	mv	s2,a0
    8000428c:	89ae                	mv	s3,a1
    8000428e:	8a32                	mv	s4,a2
    panic("dirlookup not DIR");

  for(off = 0; off < dp->size; off += sizeof(de)){
    80004290:	457c                	lw	a5,76(a0)
    80004292:	4481                	li	s1,0
      inum = de.inum;
      return iget(dp->dev, inum);
    }
  }

  return 0;
    80004294:	4501                	li	a0,0
  for(off = 0; off < dp->size; off += sizeof(de)){
    80004296:	e79d                	bnez	a5,800042c4 <dirlookup+0x54>
    80004298:	a8a5                	j	80004310 <dirlookup+0xa0>
    panic("dirlookup not DIR");
    8000429a:	00004517          	auipc	a0,0x4
    8000429e:	37650513          	addi	a0,a0,886 # 80008610 <syscalls+0x1c0>
    800042a2:	ffffc097          	auipc	ra,0xffffc
    800042a6:	29e080e7          	jalr	670(ra) # 80000540 <panic>
      panic("dirlookup read");
    800042aa:	00004517          	auipc	a0,0x4
    800042ae:	37e50513          	addi	a0,a0,894 # 80008628 <syscalls+0x1d8>
    800042b2:	ffffc097          	auipc	ra,0xffffc
    800042b6:	28e080e7          	jalr	654(ra) # 80000540 <panic>
  for(off = 0; off < dp->size; off += sizeof(de)){
    800042ba:	24c1                	addiw	s1,s1,16
    800042bc:	04c92783          	lw	a5,76(s2)
    800042c0:	04f4f763          	bgeu	s1,a5,8000430e <dirlookup+0x9e>
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800042c4:	4741                	li	a4,16
    800042c6:	86a6                	mv	a3,s1
    800042c8:	fc040613          	addi	a2,s0,-64
    800042cc:	4581                	li	a1,0
    800042ce:	854a                	mv	a0,s2
    800042d0:	00000097          	auipc	ra,0x0
    800042d4:	d70080e7          	jalr	-656(ra) # 80004040 <readi>
    800042d8:	47c1                	li	a5,16
    800042da:	fcf518e3          	bne	a0,a5,800042aa <dirlookup+0x3a>
    if(de.inum == 0)
    800042de:	fc045783          	lhu	a5,-64(s0)
    800042e2:	dfe1                	beqz	a5,800042ba <dirlookup+0x4a>
    if(namecmp(name, de.name) == 0){
    800042e4:	fc240593          	addi	a1,s0,-62
    800042e8:	854e                	mv	a0,s3
    800042ea:	00000097          	auipc	ra,0x0
    800042ee:	f6c080e7          	jalr	-148(ra) # 80004256 <namecmp>
    800042f2:	f561                	bnez	a0,800042ba <dirlookup+0x4a>
      if(poff)
    800042f4:	000a0463          	beqz	s4,800042fc <dirlookup+0x8c>
        *poff = off;
    800042f8:	009a2023          	sw	s1,0(s4)
      return iget(dp->dev, inum);
    800042fc:	fc045583          	lhu	a1,-64(s0)
    80004300:	00092503          	lw	a0,0(s2)
    80004304:	fffff097          	auipc	ra,0xfffff
    80004308:	74e080e7          	jalr	1870(ra) # 80003a52 <iget>
    8000430c:	a011                	j	80004310 <dirlookup+0xa0>
  return 0;
    8000430e:	4501                	li	a0,0
}
    80004310:	70e2                	ld	ra,56(sp)
    80004312:	7442                	ld	s0,48(sp)
    80004314:	74a2                	ld	s1,40(sp)
    80004316:	7902                	ld	s2,32(sp)
    80004318:	69e2                	ld	s3,24(sp)
    8000431a:	6a42                	ld	s4,16(sp)
    8000431c:	6121                	addi	sp,sp,64
    8000431e:	8082                	ret

0000000080004320 <namex>:
// If parent != 0, return the inode for the parent and copy the final
// path element into name, which must have room for DIRSIZ bytes.
// Must be called inside a transaction since it calls iput().
static struct inode*
namex(char *path, int nameiparent, char *name)
{
    80004320:	711d                	addi	sp,sp,-96
    80004322:	ec86                	sd	ra,88(sp)
    80004324:	e8a2                	sd	s0,80(sp)
    80004326:	e4a6                	sd	s1,72(sp)
    80004328:	e0ca                	sd	s2,64(sp)
    8000432a:	fc4e                	sd	s3,56(sp)
    8000432c:	f852                	sd	s4,48(sp)
    8000432e:	f456                	sd	s5,40(sp)
    80004330:	f05a                	sd	s6,32(sp)
    80004332:	ec5e                	sd	s7,24(sp)
    80004334:	e862                	sd	s8,16(sp)
    80004336:	e466                	sd	s9,8(sp)
    80004338:	e06a                	sd	s10,0(sp)
    8000433a:	1080                	addi	s0,sp,96
    8000433c:	84aa                	mv	s1,a0
    8000433e:	8b2e                	mv	s6,a1
    80004340:	8ab2                	mv	s5,a2
  struct inode *ip, *next;

  if(*path == '/')
    80004342:	00054703          	lbu	a4,0(a0)
    80004346:	02f00793          	li	a5,47
    8000434a:	02f70363          	beq	a4,a5,80004370 <namex+0x50>
    ip = iget(ROOTDEV, ROOTINO);
  else
    ip = idup(myproc()->cwd);
    8000434e:	ffffd097          	auipc	ra,0xffffd
    80004352:	65e080e7          	jalr	1630(ra) # 800019ac <myproc>
    80004356:	17053503          	ld	a0,368(a0)
    8000435a:	00000097          	auipc	ra,0x0
    8000435e:	9f4080e7          	jalr	-1548(ra) # 80003d4e <idup>
    80004362:	8a2a                	mv	s4,a0
  while(*path == '/')
    80004364:	02f00913          	li	s2,47
  if(len >= DIRSIZ)
    80004368:	4cb5                	li	s9,13
  len = path - s;
    8000436a:	4b81                	li	s7,0

  while((path = skipelem(path, name)) != 0){
    ilock(ip);
    if(ip->type != T_DIR){
    8000436c:	4c05                	li	s8,1
    8000436e:	a87d                	j	8000442c <namex+0x10c>
    ip = iget(ROOTDEV, ROOTINO);
    80004370:	4585                	li	a1,1
    80004372:	4505                	li	a0,1
    80004374:	fffff097          	auipc	ra,0xfffff
    80004378:	6de080e7          	jalr	1758(ra) # 80003a52 <iget>
    8000437c:	8a2a                	mv	s4,a0
    8000437e:	b7dd                	j	80004364 <namex+0x44>
      iunlockput(ip);
    80004380:	8552                	mv	a0,s4
    80004382:	00000097          	auipc	ra,0x0
    80004386:	c6c080e7          	jalr	-916(ra) # 80003fee <iunlockput>
      return 0;
    8000438a:	4a01                	li	s4,0
  if(nameiparent){
    iput(ip);
    return 0;
  }
  return ip;
}
    8000438c:	8552                	mv	a0,s4
    8000438e:	60e6                	ld	ra,88(sp)
    80004390:	6446                	ld	s0,80(sp)
    80004392:	64a6                	ld	s1,72(sp)
    80004394:	6906                	ld	s2,64(sp)
    80004396:	79e2                	ld	s3,56(sp)
    80004398:	7a42                	ld	s4,48(sp)
    8000439a:	7aa2                	ld	s5,40(sp)
    8000439c:	7b02                	ld	s6,32(sp)
    8000439e:	6be2                	ld	s7,24(sp)
    800043a0:	6c42                	ld	s8,16(sp)
    800043a2:	6ca2                	ld	s9,8(sp)
    800043a4:	6d02                	ld	s10,0(sp)
    800043a6:	6125                	addi	sp,sp,96
    800043a8:	8082                	ret
      iunlock(ip);
    800043aa:	8552                	mv	a0,s4
    800043ac:	00000097          	auipc	ra,0x0
    800043b0:	aa2080e7          	jalr	-1374(ra) # 80003e4e <iunlock>
      return ip;
    800043b4:	bfe1                	j	8000438c <namex+0x6c>
      iunlockput(ip);
    800043b6:	8552                	mv	a0,s4
    800043b8:	00000097          	auipc	ra,0x0
    800043bc:	c36080e7          	jalr	-970(ra) # 80003fee <iunlockput>
      return 0;
    800043c0:	8a4e                	mv	s4,s3
    800043c2:	b7e9                	j	8000438c <namex+0x6c>
  len = path - s;
    800043c4:	40998633          	sub	a2,s3,s1
    800043c8:	00060d1b          	sext.w	s10,a2
  if(len >= DIRSIZ)
    800043cc:	09acd863          	bge	s9,s10,8000445c <namex+0x13c>
    memmove(name, s, DIRSIZ);
    800043d0:	4639                	li	a2,14
    800043d2:	85a6                	mv	a1,s1
    800043d4:	8556                	mv	a0,s5
    800043d6:	ffffd097          	auipc	ra,0xffffd
    800043da:	958080e7          	jalr	-1704(ra) # 80000d2e <memmove>
    800043de:	84ce                	mv	s1,s3
  while(*path == '/')
    800043e0:	0004c783          	lbu	a5,0(s1)
    800043e4:	01279763          	bne	a5,s2,800043f2 <namex+0xd2>
    path++;
    800043e8:	0485                	addi	s1,s1,1
  while(*path == '/')
    800043ea:	0004c783          	lbu	a5,0(s1)
    800043ee:	ff278de3          	beq	a5,s2,800043e8 <namex+0xc8>
    ilock(ip);
    800043f2:	8552                	mv	a0,s4
    800043f4:	00000097          	auipc	ra,0x0
    800043f8:	998080e7          	jalr	-1640(ra) # 80003d8c <ilock>
    if(ip->type != T_DIR){
    800043fc:	044a1783          	lh	a5,68(s4)
    80004400:	f98790e3          	bne	a5,s8,80004380 <namex+0x60>
    if(nameiparent && *path == '\0'){
    80004404:	000b0563          	beqz	s6,8000440e <namex+0xee>
    80004408:	0004c783          	lbu	a5,0(s1)
    8000440c:	dfd9                	beqz	a5,800043aa <namex+0x8a>
    if((next = dirlookup(ip, name, 0)) == 0){
    8000440e:	865e                	mv	a2,s7
    80004410:	85d6                	mv	a1,s5
    80004412:	8552                	mv	a0,s4
    80004414:	00000097          	auipc	ra,0x0
    80004418:	e5c080e7          	jalr	-420(ra) # 80004270 <dirlookup>
    8000441c:	89aa                	mv	s3,a0
    8000441e:	dd41                	beqz	a0,800043b6 <namex+0x96>
    iunlockput(ip);
    80004420:	8552                	mv	a0,s4
    80004422:	00000097          	auipc	ra,0x0
    80004426:	bcc080e7          	jalr	-1076(ra) # 80003fee <iunlockput>
    ip = next;
    8000442a:	8a4e                	mv	s4,s3
  while(*path == '/')
    8000442c:	0004c783          	lbu	a5,0(s1)
    80004430:	01279763          	bne	a5,s2,8000443e <namex+0x11e>
    path++;
    80004434:	0485                	addi	s1,s1,1
  while(*path == '/')
    80004436:	0004c783          	lbu	a5,0(s1)
    8000443a:	ff278de3          	beq	a5,s2,80004434 <namex+0x114>
  if(*path == 0)
    8000443e:	cb9d                	beqz	a5,80004474 <namex+0x154>
  while(*path != '/' && *path != 0)
    80004440:	0004c783          	lbu	a5,0(s1)
    80004444:	89a6                	mv	s3,s1
  len = path - s;
    80004446:	8d5e                	mv	s10,s7
    80004448:	865e                	mv	a2,s7
  while(*path != '/' && *path != 0)
    8000444a:	01278963          	beq	a5,s2,8000445c <namex+0x13c>
    8000444e:	dbbd                	beqz	a5,800043c4 <namex+0xa4>
    path++;
    80004450:	0985                	addi	s3,s3,1
  while(*path != '/' && *path != 0)
    80004452:	0009c783          	lbu	a5,0(s3)
    80004456:	ff279ce3          	bne	a5,s2,8000444e <namex+0x12e>
    8000445a:	b7ad                	j	800043c4 <namex+0xa4>
    memmove(name, s, len);
    8000445c:	2601                	sext.w	a2,a2
    8000445e:	85a6                	mv	a1,s1
    80004460:	8556                	mv	a0,s5
    80004462:	ffffd097          	auipc	ra,0xffffd
    80004466:	8cc080e7          	jalr	-1844(ra) # 80000d2e <memmove>
    name[len] = 0;
    8000446a:	9d56                	add	s10,s10,s5
    8000446c:	000d0023          	sb	zero,0(s10)
    80004470:	84ce                	mv	s1,s3
    80004472:	b7bd                	j	800043e0 <namex+0xc0>
  if(nameiparent){
    80004474:	f00b0ce3          	beqz	s6,8000438c <namex+0x6c>
    iput(ip);
    80004478:	8552                	mv	a0,s4
    8000447a:	00000097          	auipc	ra,0x0
    8000447e:	acc080e7          	jalr	-1332(ra) # 80003f46 <iput>
    return 0;
    80004482:	4a01                	li	s4,0
    80004484:	b721                	j	8000438c <namex+0x6c>

0000000080004486 <dirlink>:
{
    80004486:	7139                	addi	sp,sp,-64
    80004488:	fc06                	sd	ra,56(sp)
    8000448a:	f822                	sd	s0,48(sp)
    8000448c:	f426                	sd	s1,40(sp)
    8000448e:	f04a                	sd	s2,32(sp)
    80004490:	ec4e                	sd	s3,24(sp)
    80004492:	e852                	sd	s4,16(sp)
    80004494:	0080                	addi	s0,sp,64
    80004496:	892a                	mv	s2,a0
    80004498:	8a2e                	mv	s4,a1
    8000449a:	89b2                	mv	s3,a2
  if((ip = dirlookup(dp, name, 0)) != 0){
    8000449c:	4601                	li	a2,0
    8000449e:	00000097          	auipc	ra,0x0
    800044a2:	dd2080e7          	jalr	-558(ra) # 80004270 <dirlookup>
    800044a6:	e93d                	bnez	a0,8000451c <dirlink+0x96>
  for(off = 0; off < dp->size; off += sizeof(de)){
    800044a8:	04c92483          	lw	s1,76(s2)
    800044ac:	c49d                	beqz	s1,800044da <dirlink+0x54>
    800044ae:	4481                	li	s1,0
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800044b0:	4741                	li	a4,16
    800044b2:	86a6                	mv	a3,s1
    800044b4:	fc040613          	addi	a2,s0,-64
    800044b8:	4581                	li	a1,0
    800044ba:	854a                	mv	a0,s2
    800044bc:	00000097          	auipc	ra,0x0
    800044c0:	b84080e7          	jalr	-1148(ra) # 80004040 <readi>
    800044c4:	47c1                	li	a5,16
    800044c6:	06f51163          	bne	a0,a5,80004528 <dirlink+0xa2>
    if(de.inum == 0)
    800044ca:	fc045783          	lhu	a5,-64(s0)
    800044ce:	c791                	beqz	a5,800044da <dirlink+0x54>
  for(off = 0; off < dp->size; off += sizeof(de)){
    800044d0:	24c1                	addiw	s1,s1,16
    800044d2:	04c92783          	lw	a5,76(s2)
    800044d6:	fcf4ede3          	bltu	s1,a5,800044b0 <dirlink+0x2a>
  strncpy(de.name, name, DIRSIZ);
    800044da:	4639                	li	a2,14
    800044dc:	85d2                	mv	a1,s4
    800044de:	fc240513          	addi	a0,s0,-62
    800044e2:	ffffd097          	auipc	ra,0xffffd
    800044e6:	8fc080e7          	jalr	-1796(ra) # 80000dde <strncpy>
  de.inum = inum;
    800044ea:	fd341023          	sh	s3,-64(s0)
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800044ee:	4741                	li	a4,16
    800044f0:	86a6                	mv	a3,s1
    800044f2:	fc040613          	addi	a2,s0,-64
    800044f6:	4581                	li	a1,0
    800044f8:	854a                	mv	a0,s2
    800044fa:	00000097          	auipc	ra,0x0
    800044fe:	c3e080e7          	jalr	-962(ra) # 80004138 <writei>
    80004502:	1541                	addi	a0,a0,-16
    80004504:	00a03533          	snez	a0,a0
    80004508:	40a00533          	neg	a0,a0
}
    8000450c:	70e2                	ld	ra,56(sp)
    8000450e:	7442                	ld	s0,48(sp)
    80004510:	74a2                	ld	s1,40(sp)
    80004512:	7902                	ld	s2,32(sp)
    80004514:	69e2                	ld	s3,24(sp)
    80004516:	6a42                	ld	s4,16(sp)
    80004518:	6121                	addi	sp,sp,64
    8000451a:	8082                	ret
    iput(ip);
    8000451c:	00000097          	auipc	ra,0x0
    80004520:	a2a080e7          	jalr	-1494(ra) # 80003f46 <iput>
    return -1;
    80004524:	557d                	li	a0,-1
    80004526:	b7dd                	j	8000450c <dirlink+0x86>
      panic("dirlink read");
    80004528:	00004517          	auipc	a0,0x4
    8000452c:	11050513          	addi	a0,a0,272 # 80008638 <syscalls+0x1e8>
    80004530:	ffffc097          	auipc	ra,0xffffc
    80004534:	010080e7          	jalr	16(ra) # 80000540 <panic>

0000000080004538 <namei>:

struct inode*
namei(char *path)
{
    80004538:	1101                	addi	sp,sp,-32
    8000453a:	ec06                	sd	ra,24(sp)
    8000453c:	e822                	sd	s0,16(sp)
    8000453e:	1000                	addi	s0,sp,32
  char name[DIRSIZ];
  return namex(path, 0, name);
    80004540:	fe040613          	addi	a2,s0,-32
    80004544:	4581                	li	a1,0
    80004546:	00000097          	auipc	ra,0x0
    8000454a:	dda080e7          	jalr	-550(ra) # 80004320 <namex>
}
    8000454e:	60e2                	ld	ra,24(sp)
    80004550:	6442                	ld	s0,16(sp)
    80004552:	6105                	addi	sp,sp,32
    80004554:	8082                	ret

0000000080004556 <nameiparent>:

struct inode*
nameiparent(char *path, char *name)
{
    80004556:	1141                	addi	sp,sp,-16
    80004558:	e406                	sd	ra,8(sp)
    8000455a:	e022                	sd	s0,0(sp)
    8000455c:	0800                	addi	s0,sp,16
    8000455e:	862e                	mv	a2,a1
  return namex(path, 1, name);
    80004560:	4585                	li	a1,1
    80004562:	00000097          	auipc	ra,0x0
    80004566:	dbe080e7          	jalr	-578(ra) # 80004320 <namex>
}
    8000456a:	60a2                	ld	ra,8(sp)
    8000456c:	6402                	ld	s0,0(sp)
    8000456e:	0141                	addi	sp,sp,16
    80004570:	8082                	ret

0000000080004572 <write_head>:
// Write in-memory log header to disk.
// This is the true point at which the
// current transaction commits.
static void
write_head(void)
{
    80004572:	1101                	addi	sp,sp,-32
    80004574:	ec06                	sd	ra,24(sp)
    80004576:	e822                	sd	s0,16(sp)
    80004578:	e426                	sd	s1,8(sp)
    8000457a:	e04a                	sd	s2,0(sp)
    8000457c:	1000                	addi	s0,sp,32
  struct buf *buf = bread(log.dev, log.start);
    8000457e:	0001d917          	auipc	s2,0x1d
    80004582:	3c290913          	addi	s2,s2,962 # 80021940 <log>
    80004586:	01892583          	lw	a1,24(s2)
    8000458a:	02892503          	lw	a0,40(s2)
    8000458e:	fffff097          	auipc	ra,0xfffff
    80004592:	fe6080e7          	jalr	-26(ra) # 80003574 <bread>
    80004596:	84aa                	mv	s1,a0
  struct logheader *hb = (struct logheader *) (buf->data);
  int i;
  hb->n = log.lh.n;
    80004598:	02c92683          	lw	a3,44(s2)
    8000459c:	cd34                	sw	a3,88(a0)
  for (i = 0; i < log.lh.n; i++) {
    8000459e:	02d05863          	blez	a3,800045ce <write_head+0x5c>
    800045a2:	0001d797          	auipc	a5,0x1d
    800045a6:	3ce78793          	addi	a5,a5,974 # 80021970 <log+0x30>
    800045aa:	05c50713          	addi	a4,a0,92
    800045ae:	36fd                	addiw	a3,a3,-1
    800045b0:	02069613          	slli	a2,a3,0x20
    800045b4:	01e65693          	srli	a3,a2,0x1e
    800045b8:	0001d617          	auipc	a2,0x1d
    800045bc:	3bc60613          	addi	a2,a2,956 # 80021974 <log+0x34>
    800045c0:	96b2                	add	a3,a3,a2
    hb->block[i] = log.lh.block[i];
    800045c2:	4390                	lw	a2,0(a5)
    800045c4:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    800045c6:	0791                	addi	a5,a5,4
    800045c8:	0711                	addi	a4,a4,4 # 43004 <_entry-0x7ffbcffc>
    800045ca:	fed79ce3          	bne	a5,a3,800045c2 <write_head+0x50>
  }
  bwrite(buf);
    800045ce:	8526                	mv	a0,s1
    800045d0:	fffff097          	auipc	ra,0xfffff
    800045d4:	096080e7          	jalr	150(ra) # 80003666 <bwrite>
  brelse(buf);
    800045d8:	8526                	mv	a0,s1
    800045da:	fffff097          	auipc	ra,0xfffff
    800045de:	0ca080e7          	jalr	202(ra) # 800036a4 <brelse>
}
    800045e2:	60e2                	ld	ra,24(sp)
    800045e4:	6442                	ld	s0,16(sp)
    800045e6:	64a2                	ld	s1,8(sp)
    800045e8:	6902                	ld	s2,0(sp)
    800045ea:	6105                	addi	sp,sp,32
    800045ec:	8082                	ret

00000000800045ee <install_trans>:
  for (tail = 0; tail < log.lh.n; tail++) {
    800045ee:	0001d797          	auipc	a5,0x1d
    800045f2:	37e7a783          	lw	a5,894(a5) # 8002196c <log+0x2c>
    800045f6:	0af05d63          	blez	a5,800046b0 <install_trans+0xc2>
{
    800045fa:	7139                	addi	sp,sp,-64
    800045fc:	fc06                	sd	ra,56(sp)
    800045fe:	f822                	sd	s0,48(sp)
    80004600:	f426                	sd	s1,40(sp)
    80004602:	f04a                	sd	s2,32(sp)
    80004604:	ec4e                	sd	s3,24(sp)
    80004606:	e852                	sd	s4,16(sp)
    80004608:	e456                	sd	s5,8(sp)
    8000460a:	e05a                	sd	s6,0(sp)
    8000460c:	0080                	addi	s0,sp,64
    8000460e:	8b2a                	mv	s6,a0
    80004610:	0001da97          	auipc	s5,0x1d
    80004614:	360a8a93          	addi	s5,s5,864 # 80021970 <log+0x30>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004618:	4a01                	li	s4,0
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    8000461a:	0001d997          	auipc	s3,0x1d
    8000461e:	32698993          	addi	s3,s3,806 # 80021940 <log>
    80004622:	a00d                	j	80004644 <install_trans+0x56>
    brelse(lbuf);
    80004624:	854a                	mv	a0,s2
    80004626:	fffff097          	auipc	ra,0xfffff
    8000462a:	07e080e7          	jalr	126(ra) # 800036a4 <brelse>
    brelse(dbuf);
    8000462e:	8526                	mv	a0,s1
    80004630:	fffff097          	auipc	ra,0xfffff
    80004634:	074080e7          	jalr	116(ra) # 800036a4 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004638:	2a05                	addiw	s4,s4,1
    8000463a:	0a91                	addi	s5,s5,4
    8000463c:	02c9a783          	lw	a5,44(s3)
    80004640:	04fa5e63          	bge	s4,a5,8000469c <install_trans+0xae>
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    80004644:	0189a583          	lw	a1,24(s3)
    80004648:	014585bb          	addw	a1,a1,s4
    8000464c:	2585                	addiw	a1,a1,1
    8000464e:	0289a503          	lw	a0,40(s3)
    80004652:	fffff097          	auipc	ra,0xfffff
    80004656:	f22080e7          	jalr	-222(ra) # 80003574 <bread>
    8000465a:	892a                	mv	s2,a0
    struct buf *dbuf = bread(log.dev, log.lh.block[tail]); // read dst
    8000465c:	000aa583          	lw	a1,0(s5)
    80004660:	0289a503          	lw	a0,40(s3)
    80004664:	fffff097          	auipc	ra,0xfffff
    80004668:	f10080e7          	jalr	-240(ra) # 80003574 <bread>
    8000466c:	84aa                	mv	s1,a0
    memmove(dbuf->data, lbuf->data, BSIZE);  // copy block to dst
    8000466e:	40000613          	li	a2,1024
    80004672:	05890593          	addi	a1,s2,88
    80004676:	05850513          	addi	a0,a0,88
    8000467a:	ffffc097          	auipc	ra,0xffffc
    8000467e:	6b4080e7          	jalr	1716(ra) # 80000d2e <memmove>
    bwrite(dbuf);  // write dst to disk
    80004682:	8526                	mv	a0,s1
    80004684:	fffff097          	auipc	ra,0xfffff
    80004688:	fe2080e7          	jalr	-30(ra) # 80003666 <bwrite>
    if(recovering == 0)
    8000468c:	f80b1ce3          	bnez	s6,80004624 <install_trans+0x36>
      bunpin(dbuf);
    80004690:	8526                	mv	a0,s1
    80004692:	fffff097          	auipc	ra,0xfffff
    80004696:	0ec080e7          	jalr	236(ra) # 8000377e <bunpin>
    8000469a:	b769                	j	80004624 <install_trans+0x36>
}
    8000469c:	70e2                	ld	ra,56(sp)
    8000469e:	7442                	ld	s0,48(sp)
    800046a0:	74a2                	ld	s1,40(sp)
    800046a2:	7902                	ld	s2,32(sp)
    800046a4:	69e2                	ld	s3,24(sp)
    800046a6:	6a42                	ld	s4,16(sp)
    800046a8:	6aa2                	ld	s5,8(sp)
    800046aa:	6b02                	ld	s6,0(sp)
    800046ac:	6121                	addi	sp,sp,64
    800046ae:	8082                	ret
    800046b0:	8082                	ret

00000000800046b2 <initlog>:
{
    800046b2:	7179                	addi	sp,sp,-48
    800046b4:	f406                	sd	ra,40(sp)
    800046b6:	f022                	sd	s0,32(sp)
    800046b8:	ec26                	sd	s1,24(sp)
    800046ba:	e84a                	sd	s2,16(sp)
    800046bc:	e44e                	sd	s3,8(sp)
    800046be:	1800                	addi	s0,sp,48
    800046c0:	892a                	mv	s2,a0
    800046c2:	89ae                	mv	s3,a1
  initlock(&log.lock, "log");
    800046c4:	0001d497          	auipc	s1,0x1d
    800046c8:	27c48493          	addi	s1,s1,636 # 80021940 <log>
    800046cc:	00004597          	auipc	a1,0x4
    800046d0:	f7c58593          	addi	a1,a1,-132 # 80008648 <syscalls+0x1f8>
    800046d4:	8526                	mv	a0,s1
    800046d6:	ffffc097          	auipc	ra,0xffffc
    800046da:	470080e7          	jalr	1136(ra) # 80000b46 <initlock>
  log.start = sb->logstart;
    800046de:	0149a583          	lw	a1,20(s3)
    800046e2:	cc8c                	sw	a1,24(s1)
  log.size = sb->nlog;
    800046e4:	0109a783          	lw	a5,16(s3)
    800046e8:	ccdc                	sw	a5,28(s1)
  log.dev = dev;
    800046ea:	0324a423          	sw	s2,40(s1)
  struct buf *buf = bread(log.dev, log.start);
    800046ee:	854a                	mv	a0,s2
    800046f0:	fffff097          	auipc	ra,0xfffff
    800046f4:	e84080e7          	jalr	-380(ra) # 80003574 <bread>
  log.lh.n = lh->n;
    800046f8:	4d34                	lw	a3,88(a0)
    800046fa:	d4d4                	sw	a3,44(s1)
  for (i = 0; i < log.lh.n; i++) {
    800046fc:	02d05663          	blez	a3,80004728 <initlog+0x76>
    80004700:	05c50793          	addi	a5,a0,92
    80004704:	0001d717          	auipc	a4,0x1d
    80004708:	26c70713          	addi	a4,a4,620 # 80021970 <log+0x30>
    8000470c:	36fd                	addiw	a3,a3,-1
    8000470e:	02069613          	slli	a2,a3,0x20
    80004712:	01e65693          	srli	a3,a2,0x1e
    80004716:	06050613          	addi	a2,a0,96
    8000471a:	96b2                	add	a3,a3,a2
    log.lh.block[i] = lh->block[i];
    8000471c:	4390                	lw	a2,0(a5)
    8000471e:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    80004720:	0791                	addi	a5,a5,4
    80004722:	0711                	addi	a4,a4,4
    80004724:	fed79ce3          	bne	a5,a3,8000471c <initlog+0x6a>
  brelse(buf);
    80004728:	fffff097          	auipc	ra,0xfffff
    8000472c:	f7c080e7          	jalr	-132(ra) # 800036a4 <brelse>

static void
recover_from_log(void)
{
  read_head();
  install_trans(1); // if committed, copy from log to disk
    80004730:	4505                	li	a0,1
    80004732:	00000097          	auipc	ra,0x0
    80004736:	ebc080e7          	jalr	-324(ra) # 800045ee <install_trans>
  log.lh.n = 0;
    8000473a:	0001d797          	auipc	a5,0x1d
    8000473e:	2207a923          	sw	zero,562(a5) # 8002196c <log+0x2c>
  write_head(); // clear the log
    80004742:	00000097          	auipc	ra,0x0
    80004746:	e30080e7          	jalr	-464(ra) # 80004572 <write_head>
}
    8000474a:	70a2                	ld	ra,40(sp)
    8000474c:	7402                	ld	s0,32(sp)
    8000474e:	64e2                	ld	s1,24(sp)
    80004750:	6942                	ld	s2,16(sp)
    80004752:	69a2                	ld	s3,8(sp)
    80004754:	6145                	addi	sp,sp,48
    80004756:	8082                	ret

0000000080004758 <begin_op>:
}

// called at the start of each FS system call.
void
begin_op(void)
{
    80004758:	1101                	addi	sp,sp,-32
    8000475a:	ec06                	sd	ra,24(sp)
    8000475c:	e822                	sd	s0,16(sp)
    8000475e:	e426                	sd	s1,8(sp)
    80004760:	e04a                	sd	s2,0(sp)
    80004762:	1000                	addi	s0,sp,32
  acquire(&log.lock);
    80004764:	0001d517          	auipc	a0,0x1d
    80004768:	1dc50513          	addi	a0,a0,476 # 80021940 <log>
    8000476c:	ffffc097          	auipc	ra,0xffffc
    80004770:	46a080e7          	jalr	1130(ra) # 80000bd6 <acquire>
  while(1){
    if(log.committing){
    80004774:	0001d497          	auipc	s1,0x1d
    80004778:	1cc48493          	addi	s1,s1,460 # 80021940 <log>
      sleep(&log, &log.lock);
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    8000477c:	4979                	li	s2,30
    8000477e:	a039                	j	8000478c <begin_op+0x34>
      sleep(&log, &log.lock);
    80004780:	85a6                	mv	a1,s1
    80004782:	8526                	mv	a0,s1
    80004784:	ffffe097          	auipc	ra,0xffffe
    80004788:	994080e7          	jalr	-1644(ra) # 80002118 <sleep>
    if(log.committing){
    8000478c:	50dc                	lw	a5,36(s1)
    8000478e:	fbed                	bnez	a5,80004780 <begin_op+0x28>
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    80004790:	5098                	lw	a4,32(s1)
    80004792:	2705                	addiw	a4,a4,1
    80004794:	0007069b          	sext.w	a3,a4
    80004798:	0027179b          	slliw	a5,a4,0x2
    8000479c:	9fb9                	addw	a5,a5,a4
    8000479e:	0017979b          	slliw	a5,a5,0x1
    800047a2:	54d8                	lw	a4,44(s1)
    800047a4:	9fb9                	addw	a5,a5,a4
    800047a6:	00f95963          	bge	s2,a5,800047b8 <begin_op+0x60>
      // this op might exhaust log space; wait for commit.
      sleep(&log, &log.lock);
    800047aa:	85a6                	mv	a1,s1
    800047ac:	8526                	mv	a0,s1
    800047ae:	ffffe097          	auipc	ra,0xffffe
    800047b2:	96a080e7          	jalr	-1686(ra) # 80002118 <sleep>
    800047b6:	bfd9                	j	8000478c <begin_op+0x34>
    } else {
      log.outstanding += 1;
    800047b8:	0001d517          	auipc	a0,0x1d
    800047bc:	18850513          	addi	a0,a0,392 # 80021940 <log>
    800047c0:	d114                	sw	a3,32(a0)
      release(&log.lock);
    800047c2:	ffffc097          	auipc	ra,0xffffc
    800047c6:	4c8080e7          	jalr	1224(ra) # 80000c8a <release>
      break;
    }
  }
}
    800047ca:	60e2                	ld	ra,24(sp)
    800047cc:	6442                	ld	s0,16(sp)
    800047ce:	64a2                	ld	s1,8(sp)
    800047d0:	6902                	ld	s2,0(sp)
    800047d2:	6105                	addi	sp,sp,32
    800047d4:	8082                	ret

00000000800047d6 <end_op>:

// called at the end of each FS system call.
// commits if this was the last outstanding operation.
void
end_op(void)
{
    800047d6:	7139                	addi	sp,sp,-64
    800047d8:	fc06                	sd	ra,56(sp)
    800047da:	f822                	sd	s0,48(sp)
    800047dc:	f426                	sd	s1,40(sp)
    800047de:	f04a                	sd	s2,32(sp)
    800047e0:	ec4e                	sd	s3,24(sp)
    800047e2:	e852                	sd	s4,16(sp)
    800047e4:	e456                	sd	s5,8(sp)
    800047e6:	0080                	addi	s0,sp,64
  int do_commit = 0;

  acquire(&log.lock);
    800047e8:	0001d497          	auipc	s1,0x1d
    800047ec:	15848493          	addi	s1,s1,344 # 80021940 <log>
    800047f0:	8526                	mv	a0,s1
    800047f2:	ffffc097          	auipc	ra,0xffffc
    800047f6:	3e4080e7          	jalr	996(ra) # 80000bd6 <acquire>
  log.outstanding -= 1;
    800047fa:	509c                	lw	a5,32(s1)
    800047fc:	37fd                	addiw	a5,a5,-1
    800047fe:	0007891b          	sext.w	s2,a5
    80004802:	d09c                	sw	a5,32(s1)
  if(log.committing)
    80004804:	50dc                	lw	a5,36(s1)
    80004806:	e7b9                	bnez	a5,80004854 <end_op+0x7e>
    panic("log.committing");
  if(log.outstanding == 0){
    80004808:	04091e63          	bnez	s2,80004864 <end_op+0x8e>
    do_commit = 1;
    log.committing = 1;
    8000480c:	0001d497          	auipc	s1,0x1d
    80004810:	13448493          	addi	s1,s1,308 # 80021940 <log>
    80004814:	4785                	li	a5,1
    80004816:	d0dc                	sw	a5,36(s1)
    // begin_op() may be waiting for log space,
    // and decrementing log.outstanding has decreased
    // the amount of reserved space.
    wakeup(&log);
  }
  release(&log.lock);
    80004818:	8526                	mv	a0,s1
    8000481a:	ffffc097          	auipc	ra,0xffffc
    8000481e:	470080e7          	jalr	1136(ra) # 80000c8a <release>
}

static void
commit()
{
  if (log.lh.n > 0) {
    80004822:	54dc                	lw	a5,44(s1)
    80004824:	06f04763          	bgtz	a5,80004892 <end_op+0xbc>
    acquire(&log.lock);
    80004828:	0001d497          	auipc	s1,0x1d
    8000482c:	11848493          	addi	s1,s1,280 # 80021940 <log>
    80004830:	8526                	mv	a0,s1
    80004832:	ffffc097          	auipc	ra,0xffffc
    80004836:	3a4080e7          	jalr	932(ra) # 80000bd6 <acquire>
    log.committing = 0;
    8000483a:	0204a223          	sw	zero,36(s1)
    wakeup(&log);
    8000483e:	8526                	mv	a0,s1
    80004840:	ffffe097          	auipc	ra,0xffffe
    80004844:	93c080e7          	jalr	-1732(ra) # 8000217c <wakeup>
    release(&log.lock);
    80004848:	8526                	mv	a0,s1
    8000484a:	ffffc097          	auipc	ra,0xffffc
    8000484e:	440080e7          	jalr	1088(ra) # 80000c8a <release>
}
    80004852:	a03d                	j	80004880 <end_op+0xaa>
    panic("log.committing");
    80004854:	00004517          	auipc	a0,0x4
    80004858:	dfc50513          	addi	a0,a0,-516 # 80008650 <syscalls+0x200>
    8000485c:	ffffc097          	auipc	ra,0xffffc
    80004860:	ce4080e7          	jalr	-796(ra) # 80000540 <panic>
    wakeup(&log);
    80004864:	0001d497          	auipc	s1,0x1d
    80004868:	0dc48493          	addi	s1,s1,220 # 80021940 <log>
    8000486c:	8526                	mv	a0,s1
    8000486e:	ffffe097          	auipc	ra,0xffffe
    80004872:	90e080e7          	jalr	-1778(ra) # 8000217c <wakeup>
  release(&log.lock);
    80004876:	8526                	mv	a0,s1
    80004878:	ffffc097          	auipc	ra,0xffffc
    8000487c:	412080e7          	jalr	1042(ra) # 80000c8a <release>
}
    80004880:	70e2                	ld	ra,56(sp)
    80004882:	7442                	ld	s0,48(sp)
    80004884:	74a2                	ld	s1,40(sp)
    80004886:	7902                	ld	s2,32(sp)
    80004888:	69e2                	ld	s3,24(sp)
    8000488a:	6a42                	ld	s4,16(sp)
    8000488c:	6aa2                	ld	s5,8(sp)
    8000488e:	6121                	addi	sp,sp,64
    80004890:	8082                	ret
  for (tail = 0; tail < log.lh.n; tail++) {
    80004892:	0001da97          	auipc	s5,0x1d
    80004896:	0dea8a93          	addi	s5,s5,222 # 80021970 <log+0x30>
    struct buf *to = bread(log.dev, log.start+tail+1); // log block
    8000489a:	0001da17          	auipc	s4,0x1d
    8000489e:	0a6a0a13          	addi	s4,s4,166 # 80021940 <log>
    800048a2:	018a2583          	lw	a1,24(s4)
    800048a6:	012585bb          	addw	a1,a1,s2
    800048aa:	2585                	addiw	a1,a1,1
    800048ac:	028a2503          	lw	a0,40(s4)
    800048b0:	fffff097          	auipc	ra,0xfffff
    800048b4:	cc4080e7          	jalr	-828(ra) # 80003574 <bread>
    800048b8:	84aa                	mv	s1,a0
    struct buf *from = bread(log.dev, log.lh.block[tail]); // cache block
    800048ba:	000aa583          	lw	a1,0(s5)
    800048be:	028a2503          	lw	a0,40(s4)
    800048c2:	fffff097          	auipc	ra,0xfffff
    800048c6:	cb2080e7          	jalr	-846(ra) # 80003574 <bread>
    800048ca:	89aa                	mv	s3,a0
    memmove(to->data, from->data, BSIZE);
    800048cc:	40000613          	li	a2,1024
    800048d0:	05850593          	addi	a1,a0,88
    800048d4:	05848513          	addi	a0,s1,88
    800048d8:	ffffc097          	auipc	ra,0xffffc
    800048dc:	456080e7          	jalr	1110(ra) # 80000d2e <memmove>
    bwrite(to);  // write the log
    800048e0:	8526                	mv	a0,s1
    800048e2:	fffff097          	auipc	ra,0xfffff
    800048e6:	d84080e7          	jalr	-636(ra) # 80003666 <bwrite>
    brelse(from);
    800048ea:	854e                	mv	a0,s3
    800048ec:	fffff097          	auipc	ra,0xfffff
    800048f0:	db8080e7          	jalr	-584(ra) # 800036a4 <brelse>
    brelse(to);
    800048f4:	8526                	mv	a0,s1
    800048f6:	fffff097          	auipc	ra,0xfffff
    800048fa:	dae080e7          	jalr	-594(ra) # 800036a4 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    800048fe:	2905                	addiw	s2,s2,1
    80004900:	0a91                	addi	s5,s5,4
    80004902:	02ca2783          	lw	a5,44(s4)
    80004906:	f8f94ee3          	blt	s2,a5,800048a2 <end_op+0xcc>
    write_log();     // Write modified blocks from cache to log
    write_head();    // Write header to disk -- the real commit
    8000490a:	00000097          	auipc	ra,0x0
    8000490e:	c68080e7          	jalr	-920(ra) # 80004572 <write_head>
    install_trans(0); // Now install writes to home locations
    80004912:	4501                	li	a0,0
    80004914:	00000097          	auipc	ra,0x0
    80004918:	cda080e7          	jalr	-806(ra) # 800045ee <install_trans>
    log.lh.n = 0;
    8000491c:	0001d797          	auipc	a5,0x1d
    80004920:	0407a823          	sw	zero,80(a5) # 8002196c <log+0x2c>
    write_head();    // Erase the transaction from the log
    80004924:	00000097          	auipc	ra,0x0
    80004928:	c4e080e7          	jalr	-946(ra) # 80004572 <write_head>
    8000492c:	bdf5                	j	80004828 <end_op+0x52>

000000008000492e <log_write>:
//   modify bp->data[]
//   log_write(bp)
//   brelse(bp)
void
log_write(struct buf *b)
{
    8000492e:	1101                	addi	sp,sp,-32
    80004930:	ec06                	sd	ra,24(sp)
    80004932:	e822                	sd	s0,16(sp)
    80004934:	e426                	sd	s1,8(sp)
    80004936:	e04a                	sd	s2,0(sp)
    80004938:	1000                	addi	s0,sp,32
    8000493a:	84aa                	mv	s1,a0
  int i;

  acquire(&log.lock);
    8000493c:	0001d917          	auipc	s2,0x1d
    80004940:	00490913          	addi	s2,s2,4 # 80021940 <log>
    80004944:	854a                	mv	a0,s2
    80004946:	ffffc097          	auipc	ra,0xffffc
    8000494a:	290080e7          	jalr	656(ra) # 80000bd6 <acquire>
  if (log.lh.n >= LOGSIZE || log.lh.n >= log.size - 1)
    8000494e:	02c92603          	lw	a2,44(s2)
    80004952:	47f5                	li	a5,29
    80004954:	06c7c563          	blt	a5,a2,800049be <log_write+0x90>
    80004958:	0001d797          	auipc	a5,0x1d
    8000495c:	0047a783          	lw	a5,4(a5) # 8002195c <log+0x1c>
    80004960:	37fd                	addiw	a5,a5,-1
    80004962:	04f65e63          	bge	a2,a5,800049be <log_write+0x90>
    panic("too big a transaction");
  if (log.outstanding < 1)
    80004966:	0001d797          	auipc	a5,0x1d
    8000496a:	ffa7a783          	lw	a5,-6(a5) # 80021960 <log+0x20>
    8000496e:	06f05063          	blez	a5,800049ce <log_write+0xa0>
    panic("log_write outside of trans");

  for (i = 0; i < log.lh.n; i++) {
    80004972:	4781                	li	a5,0
    80004974:	06c05563          	blez	a2,800049de <log_write+0xb0>
    if (log.lh.block[i] == b->blockno)   // log absorption
    80004978:	44cc                	lw	a1,12(s1)
    8000497a:	0001d717          	auipc	a4,0x1d
    8000497e:	ff670713          	addi	a4,a4,-10 # 80021970 <log+0x30>
  for (i = 0; i < log.lh.n; i++) {
    80004982:	4781                	li	a5,0
    if (log.lh.block[i] == b->blockno)   // log absorption
    80004984:	4314                	lw	a3,0(a4)
    80004986:	04b68c63          	beq	a3,a1,800049de <log_write+0xb0>
  for (i = 0; i < log.lh.n; i++) {
    8000498a:	2785                	addiw	a5,a5,1
    8000498c:	0711                	addi	a4,a4,4
    8000498e:	fef61be3          	bne	a2,a5,80004984 <log_write+0x56>
      break;
  }
  log.lh.block[i] = b->blockno;
    80004992:	0621                	addi	a2,a2,8
    80004994:	060a                	slli	a2,a2,0x2
    80004996:	0001d797          	auipc	a5,0x1d
    8000499a:	faa78793          	addi	a5,a5,-86 # 80021940 <log>
    8000499e:	97b2                	add	a5,a5,a2
    800049a0:	44d8                	lw	a4,12(s1)
    800049a2:	cb98                	sw	a4,16(a5)
  if (i == log.lh.n) {  // Add new block to log?
    bpin(b);
    800049a4:	8526                	mv	a0,s1
    800049a6:	fffff097          	auipc	ra,0xfffff
    800049aa:	d9c080e7          	jalr	-612(ra) # 80003742 <bpin>
    log.lh.n++;
    800049ae:	0001d717          	auipc	a4,0x1d
    800049b2:	f9270713          	addi	a4,a4,-110 # 80021940 <log>
    800049b6:	575c                	lw	a5,44(a4)
    800049b8:	2785                	addiw	a5,a5,1
    800049ba:	d75c                	sw	a5,44(a4)
    800049bc:	a82d                	j	800049f6 <log_write+0xc8>
    panic("too big a transaction");
    800049be:	00004517          	auipc	a0,0x4
    800049c2:	ca250513          	addi	a0,a0,-862 # 80008660 <syscalls+0x210>
    800049c6:	ffffc097          	auipc	ra,0xffffc
    800049ca:	b7a080e7          	jalr	-1158(ra) # 80000540 <panic>
    panic("log_write outside of trans");
    800049ce:	00004517          	auipc	a0,0x4
    800049d2:	caa50513          	addi	a0,a0,-854 # 80008678 <syscalls+0x228>
    800049d6:	ffffc097          	auipc	ra,0xffffc
    800049da:	b6a080e7          	jalr	-1174(ra) # 80000540 <panic>
  log.lh.block[i] = b->blockno;
    800049de:	00878693          	addi	a3,a5,8
    800049e2:	068a                	slli	a3,a3,0x2
    800049e4:	0001d717          	auipc	a4,0x1d
    800049e8:	f5c70713          	addi	a4,a4,-164 # 80021940 <log>
    800049ec:	9736                	add	a4,a4,a3
    800049ee:	44d4                	lw	a3,12(s1)
    800049f0:	cb14                	sw	a3,16(a4)
  if (i == log.lh.n) {  // Add new block to log?
    800049f2:	faf609e3          	beq	a2,a5,800049a4 <log_write+0x76>
  }
  release(&log.lock);
    800049f6:	0001d517          	auipc	a0,0x1d
    800049fa:	f4a50513          	addi	a0,a0,-182 # 80021940 <log>
    800049fe:	ffffc097          	auipc	ra,0xffffc
    80004a02:	28c080e7          	jalr	652(ra) # 80000c8a <release>
}
    80004a06:	60e2                	ld	ra,24(sp)
    80004a08:	6442                	ld	s0,16(sp)
    80004a0a:	64a2                	ld	s1,8(sp)
    80004a0c:	6902                	ld	s2,0(sp)
    80004a0e:	6105                	addi	sp,sp,32
    80004a10:	8082                	ret

0000000080004a12 <initsleeplock>:
#include "proc.h"
#include "sleeplock.h"

void
initsleeplock(struct sleeplock *lk, char *name)
{
    80004a12:	1101                	addi	sp,sp,-32
    80004a14:	ec06                	sd	ra,24(sp)
    80004a16:	e822                	sd	s0,16(sp)
    80004a18:	e426                	sd	s1,8(sp)
    80004a1a:	e04a                	sd	s2,0(sp)
    80004a1c:	1000                	addi	s0,sp,32
    80004a1e:	84aa                	mv	s1,a0
    80004a20:	892e                	mv	s2,a1
  initlock(&lk->lk, "sleep lock");
    80004a22:	00004597          	auipc	a1,0x4
    80004a26:	c7658593          	addi	a1,a1,-906 # 80008698 <syscalls+0x248>
    80004a2a:	0521                	addi	a0,a0,8
    80004a2c:	ffffc097          	auipc	ra,0xffffc
    80004a30:	11a080e7          	jalr	282(ra) # 80000b46 <initlock>
  lk->name = name;
    80004a34:	0324b023          	sd	s2,32(s1)
  lk->locked = 0;
    80004a38:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    80004a3c:	0204a423          	sw	zero,40(s1)
}
    80004a40:	60e2                	ld	ra,24(sp)
    80004a42:	6442                	ld	s0,16(sp)
    80004a44:	64a2                	ld	s1,8(sp)
    80004a46:	6902                	ld	s2,0(sp)
    80004a48:	6105                	addi	sp,sp,32
    80004a4a:	8082                	ret

0000000080004a4c <acquiresleep>:

void
acquiresleep(struct sleeplock *lk)
{
    80004a4c:	1101                	addi	sp,sp,-32
    80004a4e:	ec06                	sd	ra,24(sp)
    80004a50:	e822                	sd	s0,16(sp)
    80004a52:	e426                	sd	s1,8(sp)
    80004a54:	e04a                	sd	s2,0(sp)
    80004a56:	1000                	addi	s0,sp,32
    80004a58:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    80004a5a:	00850913          	addi	s2,a0,8
    80004a5e:	854a                	mv	a0,s2
    80004a60:	ffffc097          	auipc	ra,0xffffc
    80004a64:	176080e7          	jalr	374(ra) # 80000bd6 <acquire>
  while (lk->locked) {
    80004a68:	409c                	lw	a5,0(s1)
    80004a6a:	cb89                	beqz	a5,80004a7c <acquiresleep+0x30>
    sleep(lk, &lk->lk);
    80004a6c:	85ca                	mv	a1,s2
    80004a6e:	8526                	mv	a0,s1
    80004a70:	ffffd097          	auipc	ra,0xffffd
    80004a74:	6a8080e7          	jalr	1704(ra) # 80002118 <sleep>
  while (lk->locked) {
    80004a78:	409c                	lw	a5,0(s1)
    80004a7a:	fbed                	bnez	a5,80004a6c <acquiresleep+0x20>
  }
  lk->locked = 1;
    80004a7c:	4785                	li	a5,1
    80004a7e:	c09c                	sw	a5,0(s1)
  lk->pid = myproc()->pid;
    80004a80:	ffffd097          	auipc	ra,0xffffd
    80004a84:	f2c080e7          	jalr	-212(ra) # 800019ac <myproc>
    80004a88:	591c                	lw	a5,48(a0)
    80004a8a:	d49c                	sw	a5,40(s1)
  release(&lk->lk);
    80004a8c:	854a                	mv	a0,s2
    80004a8e:	ffffc097          	auipc	ra,0xffffc
    80004a92:	1fc080e7          	jalr	508(ra) # 80000c8a <release>
}
    80004a96:	60e2                	ld	ra,24(sp)
    80004a98:	6442                	ld	s0,16(sp)
    80004a9a:	64a2                	ld	s1,8(sp)
    80004a9c:	6902                	ld	s2,0(sp)
    80004a9e:	6105                	addi	sp,sp,32
    80004aa0:	8082                	ret

0000000080004aa2 <releasesleep>:

void
releasesleep(struct sleeplock *lk)
{
    80004aa2:	1101                	addi	sp,sp,-32
    80004aa4:	ec06                	sd	ra,24(sp)
    80004aa6:	e822                	sd	s0,16(sp)
    80004aa8:	e426                	sd	s1,8(sp)
    80004aaa:	e04a                	sd	s2,0(sp)
    80004aac:	1000                	addi	s0,sp,32
    80004aae:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    80004ab0:	00850913          	addi	s2,a0,8
    80004ab4:	854a                	mv	a0,s2
    80004ab6:	ffffc097          	auipc	ra,0xffffc
    80004aba:	120080e7          	jalr	288(ra) # 80000bd6 <acquire>
  lk->locked = 0;
    80004abe:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    80004ac2:	0204a423          	sw	zero,40(s1)
  wakeup(lk);
    80004ac6:	8526                	mv	a0,s1
    80004ac8:	ffffd097          	auipc	ra,0xffffd
    80004acc:	6b4080e7          	jalr	1716(ra) # 8000217c <wakeup>
  release(&lk->lk);
    80004ad0:	854a                	mv	a0,s2
    80004ad2:	ffffc097          	auipc	ra,0xffffc
    80004ad6:	1b8080e7          	jalr	440(ra) # 80000c8a <release>
}
    80004ada:	60e2                	ld	ra,24(sp)
    80004adc:	6442                	ld	s0,16(sp)
    80004ade:	64a2                	ld	s1,8(sp)
    80004ae0:	6902                	ld	s2,0(sp)
    80004ae2:	6105                	addi	sp,sp,32
    80004ae4:	8082                	ret

0000000080004ae6 <holdingsleep>:

int
holdingsleep(struct sleeplock *lk)
{
    80004ae6:	7179                	addi	sp,sp,-48
    80004ae8:	f406                	sd	ra,40(sp)
    80004aea:	f022                	sd	s0,32(sp)
    80004aec:	ec26                	sd	s1,24(sp)
    80004aee:	e84a                	sd	s2,16(sp)
    80004af0:	e44e                	sd	s3,8(sp)
    80004af2:	1800                	addi	s0,sp,48
    80004af4:	84aa                	mv	s1,a0
  int r;
  
  acquire(&lk->lk);
    80004af6:	00850913          	addi	s2,a0,8
    80004afa:	854a                	mv	a0,s2
    80004afc:	ffffc097          	auipc	ra,0xffffc
    80004b00:	0da080e7          	jalr	218(ra) # 80000bd6 <acquire>
  r = lk->locked && (lk->pid == myproc()->pid);
    80004b04:	409c                	lw	a5,0(s1)
    80004b06:	ef99                	bnez	a5,80004b24 <holdingsleep+0x3e>
    80004b08:	4481                	li	s1,0
  release(&lk->lk);
    80004b0a:	854a                	mv	a0,s2
    80004b0c:	ffffc097          	auipc	ra,0xffffc
    80004b10:	17e080e7          	jalr	382(ra) # 80000c8a <release>
  return r;
}
    80004b14:	8526                	mv	a0,s1
    80004b16:	70a2                	ld	ra,40(sp)
    80004b18:	7402                	ld	s0,32(sp)
    80004b1a:	64e2                	ld	s1,24(sp)
    80004b1c:	6942                	ld	s2,16(sp)
    80004b1e:	69a2                	ld	s3,8(sp)
    80004b20:	6145                	addi	sp,sp,48
    80004b22:	8082                	ret
  r = lk->locked && (lk->pid == myproc()->pid);
    80004b24:	0284a983          	lw	s3,40(s1)
    80004b28:	ffffd097          	auipc	ra,0xffffd
    80004b2c:	e84080e7          	jalr	-380(ra) # 800019ac <myproc>
    80004b30:	5904                	lw	s1,48(a0)
    80004b32:	413484b3          	sub	s1,s1,s3
    80004b36:	0014b493          	seqz	s1,s1
    80004b3a:	bfc1                	j	80004b0a <holdingsleep+0x24>

0000000080004b3c <fileinit>:
  struct file file[NFILE];
} ftable;

void
fileinit(void)
{
    80004b3c:	1141                	addi	sp,sp,-16
    80004b3e:	e406                	sd	ra,8(sp)
    80004b40:	e022                	sd	s0,0(sp)
    80004b42:	0800                	addi	s0,sp,16
  initlock(&ftable.lock, "ftable");
    80004b44:	00004597          	auipc	a1,0x4
    80004b48:	b6458593          	addi	a1,a1,-1180 # 800086a8 <syscalls+0x258>
    80004b4c:	0001d517          	auipc	a0,0x1d
    80004b50:	f3c50513          	addi	a0,a0,-196 # 80021a88 <ftable>
    80004b54:	ffffc097          	auipc	ra,0xffffc
    80004b58:	ff2080e7          	jalr	-14(ra) # 80000b46 <initlock>
}
    80004b5c:	60a2                	ld	ra,8(sp)
    80004b5e:	6402                	ld	s0,0(sp)
    80004b60:	0141                	addi	sp,sp,16
    80004b62:	8082                	ret

0000000080004b64 <filealloc>:

// Allocate a file structure.
struct file*
filealloc(void)
{
    80004b64:	1101                	addi	sp,sp,-32
    80004b66:	ec06                	sd	ra,24(sp)
    80004b68:	e822                	sd	s0,16(sp)
    80004b6a:	e426                	sd	s1,8(sp)
    80004b6c:	1000                	addi	s0,sp,32
  struct file *f;

  acquire(&ftable.lock);
    80004b6e:	0001d517          	auipc	a0,0x1d
    80004b72:	f1a50513          	addi	a0,a0,-230 # 80021a88 <ftable>
    80004b76:	ffffc097          	auipc	ra,0xffffc
    80004b7a:	060080e7          	jalr	96(ra) # 80000bd6 <acquire>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    80004b7e:	0001d497          	auipc	s1,0x1d
    80004b82:	f2248493          	addi	s1,s1,-222 # 80021aa0 <ftable+0x18>
    80004b86:	0001e717          	auipc	a4,0x1e
    80004b8a:	eba70713          	addi	a4,a4,-326 # 80022a40 <disk>
    if(f->ref == 0){
    80004b8e:	40dc                	lw	a5,4(s1)
    80004b90:	cf99                	beqz	a5,80004bae <filealloc+0x4a>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    80004b92:	02848493          	addi	s1,s1,40
    80004b96:	fee49ce3          	bne	s1,a4,80004b8e <filealloc+0x2a>
      f->ref = 1;
      release(&ftable.lock);
      return f;
    }
  }
  release(&ftable.lock);
    80004b9a:	0001d517          	auipc	a0,0x1d
    80004b9e:	eee50513          	addi	a0,a0,-274 # 80021a88 <ftable>
    80004ba2:	ffffc097          	auipc	ra,0xffffc
    80004ba6:	0e8080e7          	jalr	232(ra) # 80000c8a <release>
  return 0;
    80004baa:	4481                	li	s1,0
    80004bac:	a819                	j	80004bc2 <filealloc+0x5e>
      f->ref = 1;
    80004bae:	4785                	li	a5,1
    80004bb0:	c0dc                	sw	a5,4(s1)
      release(&ftable.lock);
    80004bb2:	0001d517          	auipc	a0,0x1d
    80004bb6:	ed650513          	addi	a0,a0,-298 # 80021a88 <ftable>
    80004bba:	ffffc097          	auipc	ra,0xffffc
    80004bbe:	0d0080e7          	jalr	208(ra) # 80000c8a <release>
}
    80004bc2:	8526                	mv	a0,s1
    80004bc4:	60e2                	ld	ra,24(sp)
    80004bc6:	6442                	ld	s0,16(sp)
    80004bc8:	64a2                	ld	s1,8(sp)
    80004bca:	6105                	addi	sp,sp,32
    80004bcc:	8082                	ret

0000000080004bce <filedup>:

// Increment ref count for file f.
struct file*
filedup(struct file *f)
{
    80004bce:	1101                	addi	sp,sp,-32
    80004bd0:	ec06                	sd	ra,24(sp)
    80004bd2:	e822                	sd	s0,16(sp)
    80004bd4:	e426                	sd	s1,8(sp)
    80004bd6:	1000                	addi	s0,sp,32
    80004bd8:	84aa                	mv	s1,a0
  acquire(&ftable.lock);
    80004bda:	0001d517          	auipc	a0,0x1d
    80004bde:	eae50513          	addi	a0,a0,-338 # 80021a88 <ftable>
    80004be2:	ffffc097          	auipc	ra,0xffffc
    80004be6:	ff4080e7          	jalr	-12(ra) # 80000bd6 <acquire>
  if(f->ref < 1)
    80004bea:	40dc                	lw	a5,4(s1)
    80004bec:	02f05263          	blez	a5,80004c10 <filedup+0x42>
    panic("filedup");
  f->ref++;
    80004bf0:	2785                	addiw	a5,a5,1
    80004bf2:	c0dc                	sw	a5,4(s1)
  release(&ftable.lock);
    80004bf4:	0001d517          	auipc	a0,0x1d
    80004bf8:	e9450513          	addi	a0,a0,-364 # 80021a88 <ftable>
    80004bfc:	ffffc097          	auipc	ra,0xffffc
    80004c00:	08e080e7          	jalr	142(ra) # 80000c8a <release>
  return f;
}
    80004c04:	8526                	mv	a0,s1
    80004c06:	60e2                	ld	ra,24(sp)
    80004c08:	6442                	ld	s0,16(sp)
    80004c0a:	64a2                	ld	s1,8(sp)
    80004c0c:	6105                	addi	sp,sp,32
    80004c0e:	8082                	ret
    panic("filedup");
    80004c10:	00004517          	auipc	a0,0x4
    80004c14:	aa050513          	addi	a0,a0,-1376 # 800086b0 <syscalls+0x260>
    80004c18:	ffffc097          	auipc	ra,0xffffc
    80004c1c:	928080e7          	jalr	-1752(ra) # 80000540 <panic>

0000000080004c20 <fileclose>:

// Close file f.  (Decrement ref count, close when reaches 0.)
void
fileclose(struct file *f)
{
    80004c20:	7139                	addi	sp,sp,-64
    80004c22:	fc06                	sd	ra,56(sp)
    80004c24:	f822                	sd	s0,48(sp)
    80004c26:	f426                	sd	s1,40(sp)
    80004c28:	f04a                	sd	s2,32(sp)
    80004c2a:	ec4e                	sd	s3,24(sp)
    80004c2c:	e852                	sd	s4,16(sp)
    80004c2e:	e456                	sd	s5,8(sp)
    80004c30:	0080                	addi	s0,sp,64
    80004c32:	84aa                	mv	s1,a0
  struct file ff;

  acquire(&ftable.lock);
    80004c34:	0001d517          	auipc	a0,0x1d
    80004c38:	e5450513          	addi	a0,a0,-428 # 80021a88 <ftable>
    80004c3c:	ffffc097          	auipc	ra,0xffffc
    80004c40:	f9a080e7          	jalr	-102(ra) # 80000bd6 <acquire>
  if(f->ref < 1)
    80004c44:	40dc                	lw	a5,4(s1)
    80004c46:	06f05163          	blez	a5,80004ca8 <fileclose+0x88>
    panic("fileclose");
  if(--f->ref > 0){
    80004c4a:	37fd                	addiw	a5,a5,-1
    80004c4c:	0007871b          	sext.w	a4,a5
    80004c50:	c0dc                	sw	a5,4(s1)
    80004c52:	06e04363          	bgtz	a4,80004cb8 <fileclose+0x98>
    release(&ftable.lock);
    return;
  }
  ff = *f;
    80004c56:	0004a903          	lw	s2,0(s1)
    80004c5a:	0094ca83          	lbu	s5,9(s1)
    80004c5e:	0104ba03          	ld	s4,16(s1)
    80004c62:	0184b983          	ld	s3,24(s1)
  f->ref = 0;
    80004c66:	0004a223          	sw	zero,4(s1)
  f->type = FD_NONE;
    80004c6a:	0004a023          	sw	zero,0(s1)
  release(&ftable.lock);
    80004c6e:	0001d517          	auipc	a0,0x1d
    80004c72:	e1a50513          	addi	a0,a0,-486 # 80021a88 <ftable>
    80004c76:	ffffc097          	auipc	ra,0xffffc
    80004c7a:	014080e7          	jalr	20(ra) # 80000c8a <release>

  if(ff.type == FD_PIPE){
    80004c7e:	4785                	li	a5,1
    80004c80:	04f90d63          	beq	s2,a5,80004cda <fileclose+0xba>
    pipeclose(ff.pipe, ff.writable);
  } else if(ff.type == FD_INODE || ff.type == FD_DEVICE){
    80004c84:	3979                	addiw	s2,s2,-2
    80004c86:	4785                	li	a5,1
    80004c88:	0527e063          	bltu	a5,s2,80004cc8 <fileclose+0xa8>
    begin_op();
    80004c8c:	00000097          	auipc	ra,0x0
    80004c90:	acc080e7          	jalr	-1332(ra) # 80004758 <begin_op>
    iput(ff.ip);
    80004c94:	854e                	mv	a0,s3
    80004c96:	fffff097          	auipc	ra,0xfffff
    80004c9a:	2b0080e7          	jalr	688(ra) # 80003f46 <iput>
    end_op();
    80004c9e:	00000097          	auipc	ra,0x0
    80004ca2:	b38080e7          	jalr	-1224(ra) # 800047d6 <end_op>
    80004ca6:	a00d                	j	80004cc8 <fileclose+0xa8>
    panic("fileclose");
    80004ca8:	00004517          	auipc	a0,0x4
    80004cac:	a1050513          	addi	a0,a0,-1520 # 800086b8 <syscalls+0x268>
    80004cb0:	ffffc097          	auipc	ra,0xffffc
    80004cb4:	890080e7          	jalr	-1904(ra) # 80000540 <panic>
    release(&ftable.lock);
    80004cb8:	0001d517          	auipc	a0,0x1d
    80004cbc:	dd050513          	addi	a0,a0,-560 # 80021a88 <ftable>
    80004cc0:	ffffc097          	auipc	ra,0xffffc
    80004cc4:	fca080e7          	jalr	-54(ra) # 80000c8a <release>
  }
}
    80004cc8:	70e2                	ld	ra,56(sp)
    80004cca:	7442                	ld	s0,48(sp)
    80004ccc:	74a2                	ld	s1,40(sp)
    80004cce:	7902                	ld	s2,32(sp)
    80004cd0:	69e2                	ld	s3,24(sp)
    80004cd2:	6a42                	ld	s4,16(sp)
    80004cd4:	6aa2                	ld	s5,8(sp)
    80004cd6:	6121                	addi	sp,sp,64
    80004cd8:	8082                	ret
    pipeclose(ff.pipe, ff.writable);
    80004cda:	85d6                	mv	a1,s5
    80004cdc:	8552                	mv	a0,s4
    80004cde:	00000097          	auipc	ra,0x0
    80004ce2:	34c080e7          	jalr	844(ra) # 8000502a <pipeclose>
    80004ce6:	b7cd                	j	80004cc8 <fileclose+0xa8>

0000000080004ce8 <filestat>:

// Get metadata about file f.
// addr is a user virtual address, pointing to a struct stat.
int
filestat(struct file *f, uint64 addr)
{
    80004ce8:	715d                	addi	sp,sp,-80
    80004cea:	e486                	sd	ra,72(sp)
    80004cec:	e0a2                	sd	s0,64(sp)
    80004cee:	fc26                	sd	s1,56(sp)
    80004cf0:	f84a                	sd	s2,48(sp)
    80004cf2:	f44e                	sd	s3,40(sp)
    80004cf4:	0880                	addi	s0,sp,80
    80004cf6:	84aa                	mv	s1,a0
    80004cf8:	89ae                	mv	s3,a1
  struct proc *p = myproc();
    80004cfa:	ffffd097          	auipc	ra,0xffffd
    80004cfe:	cb2080e7          	jalr	-846(ra) # 800019ac <myproc>
  struct stat st;
  
  if(f->type == FD_INODE || f->type == FD_DEVICE){
    80004d02:	409c                	lw	a5,0(s1)
    80004d04:	37f9                	addiw	a5,a5,-2
    80004d06:	4705                	li	a4,1
    80004d08:	04f76763          	bltu	a4,a5,80004d56 <filestat+0x6e>
    80004d0c:	892a                	mv	s2,a0
    ilock(f->ip);
    80004d0e:	6c88                	ld	a0,24(s1)
    80004d10:	fffff097          	auipc	ra,0xfffff
    80004d14:	07c080e7          	jalr	124(ra) # 80003d8c <ilock>
    stati(f->ip, &st);
    80004d18:	fb840593          	addi	a1,s0,-72
    80004d1c:	6c88                	ld	a0,24(s1)
    80004d1e:	fffff097          	auipc	ra,0xfffff
    80004d22:	2f8080e7          	jalr	760(ra) # 80004016 <stati>
    iunlock(f->ip);
    80004d26:	6c88                	ld	a0,24(s1)
    80004d28:	fffff097          	auipc	ra,0xfffff
    80004d2c:	126080e7          	jalr	294(ra) # 80003e4e <iunlock>
    if(copyout(p->pagetable, addr, (char *)&st, sizeof(st)) < 0)
    80004d30:	46e1                	li	a3,24
    80004d32:	fb840613          	addi	a2,s0,-72
    80004d36:	85ce                	mv	a1,s3
    80004d38:	07093503          	ld	a0,112(s2)
    80004d3c:	ffffd097          	auipc	ra,0xffffd
    80004d40:	930080e7          	jalr	-1744(ra) # 8000166c <copyout>
    80004d44:	41f5551b          	sraiw	a0,a0,0x1f
      return -1;
    return 0;
  }
  return -1;
}
    80004d48:	60a6                	ld	ra,72(sp)
    80004d4a:	6406                	ld	s0,64(sp)
    80004d4c:	74e2                	ld	s1,56(sp)
    80004d4e:	7942                	ld	s2,48(sp)
    80004d50:	79a2                	ld	s3,40(sp)
    80004d52:	6161                	addi	sp,sp,80
    80004d54:	8082                	ret
  return -1;
    80004d56:	557d                	li	a0,-1
    80004d58:	bfc5                	j	80004d48 <filestat+0x60>

0000000080004d5a <fileread>:

// Read from file f.
// addr is a user virtual address.
int
fileread(struct file *f, uint64 addr, int n)
{
    80004d5a:	7179                	addi	sp,sp,-48
    80004d5c:	f406                	sd	ra,40(sp)
    80004d5e:	f022                	sd	s0,32(sp)
    80004d60:	ec26                	sd	s1,24(sp)
    80004d62:	e84a                	sd	s2,16(sp)
    80004d64:	e44e                	sd	s3,8(sp)
    80004d66:	1800                	addi	s0,sp,48
  int r = 0;

  if(f->readable == 0)
    80004d68:	00854783          	lbu	a5,8(a0)
    80004d6c:	c3d5                	beqz	a5,80004e10 <fileread+0xb6>
    80004d6e:	84aa                	mv	s1,a0
    80004d70:	89ae                	mv	s3,a1
    80004d72:	8932                	mv	s2,a2
    return -1;

  if(f->type == FD_PIPE){
    80004d74:	411c                	lw	a5,0(a0)
    80004d76:	4705                	li	a4,1
    80004d78:	04e78963          	beq	a5,a4,80004dca <fileread+0x70>
    r = piperead(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80004d7c:	470d                	li	a4,3
    80004d7e:	04e78d63          	beq	a5,a4,80004dd8 <fileread+0x7e>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
      return -1;
    r = devsw[f->major].read(1, addr, n);
  } else if(f->type == FD_INODE){
    80004d82:	4709                	li	a4,2
    80004d84:	06e79e63          	bne	a5,a4,80004e00 <fileread+0xa6>
    ilock(f->ip);
    80004d88:	6d08                	ld	a0,24(a0)
    80004d8a:	fffff097          	auipc	ra,0xfffff
    80004d8e:	002080e7          	jalr	2(ra) # 80003d8c <ilock>
    if((r = readi(f->ip, 1, addr, f->off, n)) > 0)
    80004d92:	874a                	mv	a4,s2
    80004d94:	5094                	lw	a3,32(s1)
    80004d96:	864e                	mv	a2,s3
    80004d98:	4585                	li	a1,1
    80004d9a:	6c88                	ld	a0,24(s1)
    80004d9c:	fffff097          	auipc	ra,0xfffff
    80004da0:	2a4080e7          	jalr	676(ra) # 80004040 <readi>
    80004da4:	892a                	mv	s2,a0
    80004da6:	00a05563          	blez	a0,80004db0 <fileread+0x56>
      f->off += r;
    80004daa:	509c                	lw	a5,32(s1)
    80004dac:	9fa9                	addw	a5,a5,a0
    80004dae:	d09c                	sw	a5,32(s1)
    iunlock(f->ip);
    80004db0:	6c88                	ld	a0,24(s1)
    80004db2:	fffff097          	auipc	ra,0xfffff
    80004db6:	09c080e7          	jalr	156(ra) # 80003e4e <iunlock>
  } else {
    panic("fileread");
  }

  return r;
}
    80004dba:	854a                	mv	a0,s2
    80004dbc:	70a2                	ld	ra,40(sp)
    80004dbe:	7402                	ld	s0,32(sp)
    80004dc0:	64e2                	ld	s1,24(sp)
    80004dc2:	6942                	ld	s2,16(sp)
    80004dc4:	69a2                	ld	s3,8(sp)
    80004dc6:	6145                	addi	sp,sp,48
    80004dc8:	8082                	ret
    r = piperead(f->pipe, addr, n);
    80004dca:	6908                	ld	a0,16(a0)
    80004dcc:	00000097          	auipc	ra,0x0
    80004dd0:	3c6080e7          	jalr	966(ra) # 80005192 <piperead>
    80004dd4:	892a                	mv	s2,a0
    80004dd6:	b7d5                	j	80004dba <fileread+0x60>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
    80004dd8:	02451783          	lh	a5,36(a0)
    80004ddc:	03079693          	slli	a3,a5,0x30
    80004de0:	92c1                	srli	a3,a3,0x30
    80004de2:	4725                	li	a4,9
    80004de4:	02d76863          	bltu	a4,a3,80004e14 <fileread+0xba>
    80004de8:	0792                	slli	a5,a5,0x4
    80004dea:	0001d717          	auipc	a4,0x1d
    80004dee:	bfe70713          	addi	a4,a4,-1026 # 800219e8 <devsw>
    80004df2:	97ba                	add	a5,a5,a4
    80004df4:	639c                	ld	a5,0(a5)
    80004df6:	c38d                	beqz	a5,80004e18 <fileread+0xbe>
    r = devsw[f->major].read(1, addr, n);
    80004df8:	4505                	li	a0,1
    80004dfa:	9782                	jalr	a5
    80004dfc:	892a                	mv	s2,a0
    80004dfe:	bf75                	j	80004dba <fileread+0x60>
    panic("fileread");
    80004e00:	00004517          	auipc	a0,0x4
    80004e04:	8c850513          	addi	a0,a0,-1848 # 800086c8 <syscalls+0x278>
    80004e08:	ffffb097          	auipc	ra,0xffffb
    80004e0c:	738080e7          	jalr	1848(ra) # 80000540 <panic>
    return -1;
    80004e10:	597d                	li	s2,-1
    80004e12:	b765                	j	80004dba <fileread+0x60>
      return -1;
    80004e14:	597d                	li	s2,-1
    80004e16:	b755                	j	80004dba <fileread+0x60>
    80004e18:	597d                	li	s2,-1
    80004e1a:	b745                	j	80004dba <fileread+0x60>

0000000080004e1c <filewrite>:

// Write to file f.
// addr is a user virtual address.
int
filewrite(struct file *f, uint64 addr, int n)
{
    80004e1c:	715d                	addi	sp,sp,-80
    80004e1e:	e486                	sd	ra,72(sp)
    80004e20:	e0a2                	sd	s0,64(sp)
    80004e22:	fc26                	sd	s1,56(sp)
    80004e24:	f84a                	sd	s2,48(sp)
    80004e26:	f44e                	sd	s3,40(sp)
    80004e28:	f052                	sd	s4,32(sp)
    80004e2a:	ec56                	sd	s5,24(sp)
    80004e2c:	e85a                	sd	s6,16(sp)
    80004e2e:	e45e                	sd	s7,8(sp)
    80004e30:	e062                	sd	s8,0(sp)
    80004e32:	0880                	addi	s0,sp,80
  int r, ret = 0;

  if(f->writable == 0)
    80004e34:	00954783          	lbu	a5,9(a0)
    80004e38:	10078663          	beqz	a5,80004f44 <filewrite+0x128>
    80004e3c:	892a                	mv	s2,a0
    80004e3e:	8b2e                	mv	s6,a1
    80004e40:	8a32                	mv	s4,a2
    return -1;

  if(f->type == FD_PIPE){
    80004e42:	411c                	lw	a5,0(a0)
    80004e44:	4705                	li	a4,1
    80004e46:	02e78263          	beq	a5,a4,80004e6a <filewrite+0x4e>
    ret = pipewrite(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80004e4a:	470d                	li	a4,3
    80004e4c:	02e78663          	beq	a5,a4,80004e78 <filewrite+0x5c>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
      return -1;
    ret = devsw[f->major].write(1, addr, n);
  } else if(f->type == FD_INODE){
    80004e50:	4709                	li	a4,2
    80004e52:	0ee79163          	bne	a5,a4,80004f34 <filewrite+0x118>
    // and 2 blocks of slop for non-aligned writes.
    // this really belongs lower down, since writei()
    // might be writing a device like the console.
    int max = ((MAXOPBLOCKS-1-1-2) / 2) * BSIZE;
    int i = 0;
    while(i < n){
    80004e56:	0ac05d63          	blez	a2,80004f10 <filewrite+0xf4>
    int i = 0;
    80004e5a:	4981                	li	s3,0
    80004e5c:	6b85                	lui	s7,0x1
    80004e5e:	c00b8b93          	addi	s7,s7,-1024 # c00 <_entry-0x7ffff400>
    80004e62:	6c05                	lui	s8,0x1
    80004e64:	c00c0c1b          	addiw	s8,s8,-1024 # c00 <_entry-0x7ffff400>
    80004e68:	a861                	j	80004f00 <filewrite+0xe4>
    ret = pipewrite(f->pipe, addr, n);
    80004e6a:	6908                	ld	a0,16(a0)
    80004e6c:	00000097          	auipc	ra,0x0
    80004e70:	22e080e7          	jalr	558(ra) # 8000509a <pipewrite>
    80004e74:	8a2a                	mv	s4,a0
    80004e76:	a045                	j	80004f16 <filewrite+0xfa>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
    80004e78:	02451783          	lh	a5,36(a0)
    80004e7c:	03079693          	slli	a3,a5,0x30
    80004e80:	92c1                	srli	a3,a3,0x30
    80004e82:	4725                	li	a4,9
    80004e84:	0cd76263          	bltu	a4,a3,80004f48 <filewrite+0x12c>
    80004e88:	0792                	slli	a5,a5,0x4
    80004e8a:	0001d717          	auipc	a4,0x1d
    80004e8e:	b5e70713          	addi	a4,a4,-1186 # 800219e8 <devsw>
    80004e92:	97ba                	add	a5,a5,a4
    80004e94:	679c                	ld	a5,8(a5)
    80004e96:	cbdd                	beqz	a5,80004f4c <filewrite+0x130>
    ret = devsw[f->major].write(1, addr, n);
    80004e98:	4505                	li	a0,1
    80004e9a:	9782                	jalr	a5
    80004e9c:	8a2a                	mv	s4,a0
    80004e9e:	a8a5                	j	80004f16 <filewrite+0xfa>
    80004ea0:	00048a9b          	sext.w	s5,s1
      int n1 = n - i;
      if(n1 > max)
        n1 = max;

      begin_op();
    80004ea4:	00000097          	auipc	ra,0x0
    80004ea8:	8b4080e7          	jalr	-1868(ra) # 80004758 <begin_op>
      ilock(f->ip);
    80004eac:	01893503          	ld	a0,24(s2)
    80004eb0:	fffff097          	auipc	ra,0xfffff
    80004eb4:	edc080e7          	jalr	-292(ra) # 80003d8c <ilock>
      if ((r = writei(f->ip, 1, addr + i, f->off, n1)) > 0)
    80004eb8:	8756                	mv	a4,s5
    80004eba:	02092683          	lw	a3,32(s2)
    80004ebe:	01698633          	add	a2,s3,s6
    80004ec2:	4585                	li	a1,1
    80004ec4:	01893503          	ld	a0,24(s2)
    80004ec8:	fffff097          	auipc	ra,0xfffff
    80004ecc:	270080e7          	jalr	624(ra) # 80004138 <writei>
    80004ed0:	84aa                	mv	s1,a0
    80004ed2:	00a05763          	blez	a0,80004ee0 <filewrite+0xc4>
        f->off += r;
    80004ed6:	02092783          	lw	a5,32(s2)
    80004eda:	9fa9                	addw	a5,a5,a0
    80004edc:	02f92023          	sw	a5,32(s2)
      iunlock(f->ip);
    80004ee0:	01893503          	ld	a0,24(s2)
    80004ee4:	fffff097          	auipc	ra,0xfffff
    80004ee8:	f6a080e7          	jalr	-150(ra) # 80003e4e <iunlock>
      end_op();
    80004eec:	00000097          	auipc	ra,0x0
    80004ef0:	8ea080e7          	jalr	-1814(ra) # 800047d6 <end_op>

      if(r != n1){
    80004ef4:	009a9f63          	bne	s5,s1,80004f12 <filewrite+0xf6>
        // error from writei
        break;
      }
      i += r;
    80004ef8:	013489bb          	addw	s3,s1,s3
    while(i < n){
    80004efc:	0149db63          	bge	s3,s4,80004f12 <filewrite+0xf6>
      int n1 = n - i;
    80004f00:	413a04bb          	subw	s1,s4,s3
    80004f04:	0004879b          	sext.w	a5,s1
    80004f08:	f8fbdce3          	bge	s7,a5,80004ea0 <filewrite+0x84>
    80004f0c:	84e2                	mv	s1,s8
    80004f0e:	bf49                	j	80004ea0 <filewrite+0x84>
    int i = 0;
    80004f10:	4981                	li	s3,0
    }
    ret = (i == n ? n : -1);
    80004f12:	013a1f63          	bne	s4,s3,80004f30 <filewrite+0x114>
  } else {
    panic("filewrite");
  }

  return ret;
}
    80004f16:	8552                	mv	a0,s4
    80004f18:	60a6                	ld	ra,72(sp)
    80004f1a:	6406                	ld	s0,64(sp)
    80004f1c:	74e2                	ld	s1,56(sp)
    80004f1e:	7942                	ld	s2,48(sp)
    80004f20:	79a2                	ld	s3,40(sp)
    80004f22:	7a02                	ld	s4,32(sp)
    80004f24:	6ae2                	ld	s5,24(sp)
    80004f26:	6b42                	ld	s6,16(sp)
    80004f28:	6ba2                	ld	s7,8(sp)
    80004f2a:	6c02                	ld	s8,0(sp)
    80004f2c:	6161                	addi	sp,sp,80
    80004f2e:	8082                	ret
    ret = (i == n ? n : -1);
    80004f30:	5a7d                	li	s4,-1
    80004f32:	b7d5                	j	80004f16 <filewrite+0xfa>
    panic("filewrite");
    80004f34:	00003517          	auipc	a0,0x3
    80004f38:	7a450513          	addi	a0,a0,1956 # 800086d8 <syscalls+0x288>
    80004f3c:	ffffb097          	auipc	ra,0xffffb
    80004f40:	604080e7          	jalr	1540(ra) # 80000540 <panic>
    return -1;
    80004f44:	5a7d                	li	s4,-1
    80004f46:	bfc1                	j	80004f16 <filewrite+0xfa>
      return -1;
    80004f48:	5a7d                	li	s4,-1
    80004f4a:	b7f1                	j	80004f16 <filewrite+0xfa>
    80004f4c:	5a7d                	li	s4,-1
    80004f4e:	b7e1                	j	80004f16 <filewrite+0xfa>

0000000080004f50 <pipealloc>:
  int writeopen;  // write fd is still open
};

int
pipealloc(struct file **f0, struct file **f1)
{
    80004f50:	7179                	addi	sp,sp,-48
    80004f52:	f406                	sd	ra,40(sp)
    80004f54:	f022                	sd	s0,32(sp)
    80004f56:	ec26                	sd	s1,24(sp)
    80004f58:	e84a                	sd	s2,16(sp)
    80004f5a:	e44e                	sd	s3,8(sp)
    80004f5c:	e052                	sd	s4,0(sp)
    80004f5e:	1800                	addi	s0,sp,48
    80004f60:	84aa                	mv	s1,a0
    80004f62:	8a2e                	mv	s4,a1
  struct pipe *pi;

  pi = 0;
  *f0 = *f1 = 0;
    80004f64:	0005b023          	sd	zero,0(a1)
    80004f68:	00053023          	sd	zero,0(a0)
  if((*f0 = filealloc()) == 0 || (*f1 = filealloc()) == 0)
    80004f6c:	00000097          	auipc	ra,0x0
    80004f70:	bf8080e7          	jalr	-1032(ra) # 80004b64 <filealloc>
    80004f74:	e088                	sd	a0,0(s1)
    80004f76:	c551                	beqz	a0,80005002 <pipealloc+0xb2>
    80004f78:	00000097          	auipc	ra,0x0
    80004f7c:	bec080e7          	jalr	-1044(ra) # 80004b64 <filealloc>
    80004f80:	00aa3023          	sd	a0,0(s4)
    80004f84:	c92d                	beqz	a0,80004ff6 <pipealloc+0xa6>
    goto bad;
  if((pi = (struct pipe*)kalloc()) == 0)
    80004f86:	ffffc097          	auipc	ra,0xffffc
    80004f8a:	b60080e7          	jalr	-1184(ra) # 80000ae6 <kalloc>
    80004f8e:	892a                	mv	s2,a0
    80004f90:	c125                	beqz	a0,80004ff0 <pipealloc+0xa0>
    goto bad;
  pi->readopen = 1;
    80004f92:	4985                	li	s3,1
    80004f94:	23352023          	sw	s3,544(a0)
  pi->writeopen = 1;
    80004f98:	23352223          	sw	s3,548(a0)
  pi->nwrite = 0;
    80004f9c:	20052e23          	sw	zero,540(a0)
  pi->nread = 0;
    80004fa0:	20052c23          	sw	zero,536(a0)
  initlock(&pi->lock, "pipe");
    80004fa4:	00003597          	auipc	a1,0x3
    80004fa8:	74458593          	addi	a1,a1,1860 # 800086e8 <syscalls+0x298>
    80004fac:	ffffc097          	auipc	ra,0xffffc
    80004fb0:	b9a080e7          	jalr	-1126(ra) # 80000b46 <initlock>
  (*f0)->type = FD_PIPE;
    80004fb4:	609c                	ld	a5,0(s1)
    80004fb6:	0137a023          	sw	s3,0(a5)
  (*f0)->readable = 1;
    80004fba:	609c                	ld	a5,0(s1)
    80004fbc:	01378423          	sb	s3,8(a5)
  (*f0)->writable = 0;
    80004fc0:	609c                	ld	a5,0(s1)
    80004fc2:	000784a3          	sb	zero,9(a5)
  (*f0)->pipe = pi;
    80004fc6:	609c                	ld	a5,0(s1)
    80004fc8:	0127b823          	sd	s2,16(a5)
  (*f1)->type = FD_PIPE;
    80004fcc:	000a3783          	ld	a5,0(s4)
    80004fd0:	0137a023          	sw	s3,0(a5)
  (*f1)->readable = 0;
    80004fd4:	000a3783          	ld	a5,0(s4)
    80004fd8:	00078423          	sb	zero,8(a5)
  (*f1)->writable = 1;
    80004fdc:	000a3783          	ld	a5,0(s4)
    80004fe0:	013784a3          	sb	s3,9(a5)
  (*f1)->pipe = pi;
    80004fe4:	000a3783          	ld	a5,0(s4)
    80004fe8:	0127b823          	sd	s2,16(a5)
  return 0;
    80004fec:	4501                	li	a0,0
    80004fee:	a025                	j	80005016 <pipealloc+0xc6>

 bad:
  if(pi)
    kfree((char*)pi);
  if(*f0)
    80004ff0:	6088                	ld	a0,0(s1)
    80004ff2:	e501                	bnez	a0,80004ffa <pipealloc+0xaa>
    80004ff4:	a039                	j	80005002 <pipealloc+0xb2>
    80004ff6:	6088                	ld	a0,0(s1)
    80004ff8:	c51d                	beqz	a0,80005026 <pipealloc+0xd6>
    fileclose(*f0);
    80004ffa:	00000097          	auipc	ra,0x0
    80004ffe:	c26080e7          	jalr	-986(ra) # 80004c20 <fileclose>
  if(*f1)
    80005002:	000a3783          	ld	a5,0(s4)
    fileclose(*f1);
  return -1;
    80005006:	557d                	li	a0,-1
  if(*f1)
    80005008:	c799                	beqz	a5,80005016 <pipealloc+0xc6>
    fileclose(*f1);
    8000500a:	853e                	mv	a0,a5
    8000500c:	00000097          	auipc	ra,0x0
    80005010:	c14080e7          	jalr	-1004(ra) # 80004c20 <fileclose>
  return -1;
    80005014:	557d                	li	a0,-1
}
    80005016:	70a2                	ld	ra,40(sp)
    80005018:	7402                	ld	s0,32(sp)
    8000501a:	64e2                	ld	s1,24(sp)
    8000501c:	6942                	ld	s2,16(sp)
    8000501e:	69a2                	ld	s3,8(sp)
    80005020:	6a02                	ld	s4,0(sp)
    80005022:	6145                	addi	sp,sp,48
    80005024:	8082                	ret
  return -1;
    80005026:	557d                	li	a0,-1
    80005028:	b7fd                	j	80005016 <pipealloc+0xc6>

000000008000502a <pipeclose>:

void
pipeclose(struct pipe *pi, int writable)
{
    8000502a:	1101                	addi	sp,sp,-32
    8000502c:	ec06                	sd	ra,24(sp)
    8000502e:	e822                	sd	s0,16(sp)
    80005030:	e426                	sd	s1,8(sp)
    80005032:	e04a                	sd	s2,0(sp)
    80005034:	1000                	addi	s0,sp,32
    80005036:	84aa                	mv	s1,a0
    80005038:	892e                	mv	s2,a1
  acquire(&pi->lock);
    8000503a:	ffffc097          	auipc	ra,0xffffc
    8000503e:	b9c080e7          	jalr	-1124(ra) # 80000bd6 <acquire>
  if(writable){
    80005042:	02090d63          	beqz	s2,8000507c <pipeclose+0x52>
    pi->writeopen = 0;
    80005046:	2204a223          	sw	zero,548(s1)
    wakeup(&pi->nread);
    8000504a:	21848513          	addi	a0,s1,536
    8000504e:	ffffd097          	auipc	ra,0xffffd
    80005052:	12e080e7          	jalr	302(ra) # 8000217c <wakeup>
  } else {
    pi->readopen = 0;
    wakeup(&pi->nwrite);
  }
  if(pi->readopen == 0 && pi->writeopen == 0){
    80005056:	2204b783          	ld	a5,544(s1)
    8000505a:	eb95                	bnez	a5,8000508e <pipeclose+0x64>
    release(&pi->lock);
    8000505c:	8526                	mv	a0,s1
    8000505e:	ffffc097          	auipc	ra,0xffffc
    80005062:	c2c080e7          	jalr	-980(ra) # 80000c8a <release>
    kfree((char*)pi);
    80005066:	8526                	mv	a0,s1
    80005068:	ffffc097          	auipc	ra,0xffffc
    8000506c:	980080e7          	jalr	-1664(ra) # 800009e8 <kfree>
  } else
    release(&pi->lock);
}
    80005070:	60e2                	ld	ra,24(sp)
    80005072:	6442                	ld	s0,16(sp)
    80005074:	64a2                	ld	s1,8(sp)
    80005076:	6902                	ld	s2,0(sp)
    80005078:	6105                	addi	sp,sp,32
    8000507a:	8082                	ret
    pi->readopen = 0;
    8000507c:	2204a023          	sw	zero,544(s1)
    wakeup(&pi->nwrite);
    80005080:	21c48513          	addi	a0,s1,540
    80005084:	ffffd097          	auipc	ra,0xffffd
    80005088:	0f8080e7          	jalr	248(ra) # 8000217c <wakeup>
    8000508c:	b7e9                	j	80005056 <pipeclose+0x2c>
    release(&pi->lock);
    8000508e:	8526                	mv	a0,s1
    80005090:	ffffc097          	auipc	ra,0xffffc
    80005094:	bfa080e7          	jalr	-1030(ra) # 80000c8a <release>
}
    80005098:	bfe1                	j	80005070 <pipeclose+0x46>

000000008000509a <pipewrite>:

int
pipewrite(struct pipe *pi, uint64 addr, int n)
{
    8000509a:	711d                	addi	sp,sp,-96
    8000509c:	ec86                	sd	ra,88(sp)
    8000509e:	e8a2                	sd	s0,80(sp)
    800050a0:	e4a6                	sd	s1,72(sp)
    800050a2:	e0ca                	sd	s2,64(sp)
    800050a4:	fc4e                	sd	s3,56(sp)
    800050a6:	f852                	sd	s4,48(sp)
    800050a8:	f456                	sd	s5,40(sp)
    800050aa:	f05a                	sd	s6,32(sp)
    800050ac:	ec5e                	sd	s7,24(sp)
    800050ae:	e862                	sd	s8,16(sp)
    800050b0:	1080                	addi	s0,sp,96
    800050b2:	84aa                	mv	s1,a0
    800050b4:	8aae                	mv	s5,a1
    800050b6:	8a32                	mv	s4,a2
  int i = 0;
  struct proc *pr = myproc();
    800050b8:	ffffd097          	auipc	ra,0xffffd
    800050bc:	8f4080e7          	jalr	-1804(ra) # 800019ac <myproc>
    800050c0:	89aa                	mv	s3,a0

  acquire(&pi->lock);
    800050c2:	8526                	mv	a0,s1
    800050c4:	ffffc097          	auipc	ra,0xffffc
    800050c8:	b12080e7          	jalr	-1262(ra) # 80000bd6 <acquire>
  while(i < n){
    800050cc:	0b405663          	blez	s4,80005178 <pipewrite+0xde>
  int i = 0;
    800050d0:	4901                	li	s2,0
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
      wakeup(&pi->nread);
      sleep(&pi->nwrite, &pi->lock);
    } else {
      char ch;
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    800050d2:	5b7d                	li	s6,-1
      wakeup(&pi->nread);
    800050d4:	21848c13          	addi	s8,s1,536
      sleep(&pi->nwrite, &pi->lock);
    800050d8:	21c48b93          	addi	s7,s1,540
    800050dc:	a089                	j	8000511e <pipewrite+0x84>
      release(&pi->lock);
    800050de:	8526                	mv	a0,s1
    800050e0:	ffffc097          	auipc	ra,0xffffc
    800050e4:	baa080e7          	jalr	-1110(ra) # 80000c8a <release>
      return -1;
    800050e8:	597d                	li	s2,-1
  }
  wakeup(&pi->nread);
  release(&pi->lock);

  return i;
}
    800050ea:	854a                	mv	a0,s2
    800050ec:	60e6                	ld	ra,88(sp)
    800050ee:	6446                	ld	s0,80(sp)
    800050f0:	64a6                	ld	s1,72(sp)
    800050f2:	6906                	ld	s2,64(sp)
    800050f4:	79e2                	ld	s3,56(sp)
    800050f6:	7a42                	ld	s4,48(sp)
    800050f8:	7aa2                	ld	s5,40(sp)
    800050fa:	7b02                	ld	s6,32(sp)
    800050fc:	6be2                	ld	s7,24(sp)
    800050fe:	6c42                	ld	s8,16(sp)
    80005100:	6125                	addi	sp,sp,96
    80005102:	8082                	ret
      wakeup(&pi->nread);
    80005104:	8562                	mv	a0,s8
    80005106:	ffffd097          	auipc	ra,0xffffd
    8000510a:	076080e7          	jalr	118(ra) # 8000217c <wakeup>
      sleep(&pi->nwrite, &pi->lock);
    8000510e:	85a6                	mv	a1,s1
    80005110:	855e                	mv	a0,s7
    80005112:	ffffd097          	auipc	ra,0xffffd
    80005116:	006080e7          	jalr	6(ra) # 80002118 <sleep>
  while(i < n){
    8000511a:	07495063          	bge	s2,s4,8000517a <pipewrite+0xe0>
    if(pi->readopen == 0 || killed(pr)){
    8000511e:	2204a783          	lw	a5,544(s1)
    80005122:	dfd5                	beqz	a5,800050de <pipewrite+0x44>
    80005124:	854e                	mv	a0,s3
    80005126:	ffffd097          	auipc	ra,0xffffd
    8000512a:	2c6080e7          	jalr	710(ra) # 800023ec <killed>
    8000512e:	f945                	bnez	a0,800050de <pipewrite+0x44>
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
    80005130:	2184a783          	lw	a5,536(s1)
    80005134:	21c4a703          	lw	a4,540(s1)
    80005138:	2007879b          	addiw	a5,a5,512
    8000513c:	fcf704e3          	beq	a4,a5,80005104 <pipewrite+0x6a>
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80005140:	4685                	li	a3,1
    80005142:	01590633          	add	a2,s2,s5
    80005146:	faf40593          	addi	a1,s0,-81
    8000514a:	0709b503          	ld	a0,112(s3)
    8000514e:	ffffc097          	auipc	ra,0xffffc
    80005152:	5aa080e7          	jalr	1450(ra) # 800016f8 <copyin>
    80005156:	03650263          	beq	a0,s6,8000517a <pipewrite+0xe0>
      pi->data[pi->nwrite++ % PIPESIZE] = ch;
    8000515a:	21c4a783          	lw	a5,540(s1)
    8000515e:	0017871b          	addiw	a4,a5,1
    80005162:	20e4ae23          	sw	a4,540(s1)
    80005166:	1ff7f793          	andi	a5,a5,511
    8000516a:	97a6                	add	a5,a5,s1
    8000516c:	faf44703          	lbu	a4,-81(s0)
    80005170:	00e78c23          	sb	a4,24(a5)
      i++;
    80005174:	2905                	addiw	s2,s2,1
    80005176:	b755                	j	8000511a <pipewrite+0x80>
  int i = 0;
    80005178:	4901                	li	s2,0
  wakeup(&pi->nread);
    8000517a:	21848513          	addi	a0,s1,536
    8000517e:	ffffd097          	auipc	ra,0xffffd
    80005182:	ffe080e7          	jalr	-2(ra) # 8000217c <wakeup>
  release(&pi->lock);
    80005186:	8526                	mv	a0,s1
    80005188:	ffffc097          	auipc	ra,0xffffc
    8000518c:	b02080e7          	jalr	-1278(ra) # 80000c8a <release>
  return i;
    80005190:	bfa9                	j	800050ea <pipewrite+0x50>

0000000080005192 <piperead>:

int
piperead(struct pipe *pi, uint64 addr, int n)
{
    80005192:	715d                	addi	sp,sp,-80
    80005194:	e486                	sd	ra,72(sp)
    80005196:	e0a2                	sd	s0,64(sp)
    80005198:	fc26                	sd	s1,56(sp)
    8000519a:	f84a                	sd	s2,48(sp)
    8000519c:	f44e                	sd	s3,40(sp)
    8000519e:	f052                	sd	s4,32(sp)
    800051a0:	ec56                	sd	s5,24(sp)
    800051a2:	e85a                	sd	s6,16(sp)
    800051a4:	0880                	addi	s0,sp,80
    800051a6:	84aa                	mv	s1,a0
    800051a8:	892e                	mv	s2,a1
    800051aa:	8ab2                	mv	s5,a2
  int i;
  struct proc *pr = myproc();
    800051ac:	ffffd097          	auipc	ra,0xffffd
    800051b0:	800080e7          	jalr	-2048(ra) # 800019ac <myproc>
    800051b4:	8a2a                	mv	s4,a0
  char ch;

  acquire(&pi->lock);
    800051b6:	8526                	mv	a0,s1
    800051b8:	ffffc097          	auipc	ra,0xffffc
    800051bc:	a1e080e7          	jalr	-1506(ra) # 80000bd6 <acquire>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    800051c0:	2184a703          	lw	a4,536(s1)
    800051c4:	21c4a783          	lw	a5,540(s1)
    if(killed(pr)){
      release(&pi->lock);
      return -1;
    }
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    800051c8:	21848993          	addi	s3,s1,536
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    800051cc:	02f71763          	bne	a4,a5,800051fa <piperead+0x68>
    800051d0:	2244a783          	lw	a5,548(s1)
    800051d4:	c39d                	beqz	a5,800051fa <piperead+0x68>
    if(killed(pr)){
    800051d6:	8552                	mv	a0,s4
    800051d8:	ffffd097          	auipc	ra,0xffffd
    800051dc:	214080e7          	jalr	532(ra) # 800023ec <killed>
    800051e0:	e949                	bnez	a0,80005272 <piperead+0xe0>
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    800051e2:	85a6                	mv	a1,s1
    800051e4:	854e                	mv	a0,s3
    800051e6:	ffffd097          	auipc	ra,0xffffd
    800051ea:	f32080e7          	jalr	-206(ra) # 80002118 <sleep>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    800051ee:	2184a703          	lw	a4,536(s1)
    800051f2:	21c4a783          	lw	a5,540(s1)
    800051f6:	fcf70de3          	beq	a4,a5,800051d0 <piperead+0x3e>
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    800051fa:	4981                	li	s3,0
    if(pi->nread == pi->nwrite)
      break;
    ch = pi->data[pi->nread++ % PIPESIZE];
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    800051fc:	5b7d                	li	s6,-1
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    800051fe:	05505463          	blez	s5,80005246 <piperead+0xb4>
    if(pi->nread == pi->nwrite)
    80005202:	2184a783          	lw	a5,536(s1)
    80005206:	21c4a703          	lw	a4,540(s1)
    8000520a:	02f70e63          	beq	a4,a5,80005246 <piperead+0xb4>
    ch = pi->data[pi->nread++ % PIPESIZE];
    8000520e:	0017871b          	addiw	a4,a5,1
    80005212:	20e4ac23          	sw	a4,536(s1)
    80005216:	1ff7f793          	andi	a5,a5,511
    8000521a:	97a6                	add	a5,a5,s1
    8000521c:	0187c783          	lbu	a5,24(a5)
    80005220:	faf40fa3          	sb	a5,-65(s0)
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80005224:	4685                	li	a3,1
    80005226:	fbf40613          	addi	a2,s0,-65
    8000522a:	85ca                	mv	a1,s2
    8000522c:	070a3503          	ld	a0,112(s4)
    80005230:	ffffc097          	auipc	ra,0xffffc
    80005234:	43c080e7          	jalr	1084(ra) # 8000166c <copyout>
    80005238:	01650763          	beq	a0,s6,80005246 <piperead+0xb4>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    8000523c:	2985                	addiw	s3,s3,1
    8000523e:	0905                	addi	s2,s2,1
    80005240:	fd3a91e3          	bne	s5,s3,80005202 <piperead+0x70>
    80005244:	89d6                	mv	s3,s5
      break;
  }
  wakeup(&pi->nwrite);  //DOC: piperead-wakeup
    80005246:	21c48513          	addi	a0,s1,540
    8000524a:	ffffd097          	auipc	ra,0xffffd
    8000524e:	f32080e7          	jalr	-206(ra) # 8000217c <wakeup>
  release(&pi->lock);
    80005252:	8526                	mv	a0,s1
    80005254:	ffffc097          	auipc	ra,0xffffc
    80005258:	a36080e7          	jalr	-1482(ra) # 80000c8a <release>
  return i;
}
    8000525c:	854e                	mv	a0,s3
    8000525e:	60a6                	ld	ra,72(sp)
    80005260:	6406                	ld	s0,64(sp)
    80005262:	74e2                	ld	s1,56(sp)
    80005264:	7942                	ld	s2,48(sp)
    80005266:	79a2                	ld	s3,40(sp)
    80005268:	7a02                	ld	s4,32(sp)
    8000526a:	6ae2                	ld	s5,24(sp)
    8000526c:	6b42                	ld	s6,16(sp)
    8000526e:	6161                	addi	sp,sp,80
    80005270:	8082                	ret
      release(&pi->lock);
    80005272:	8526                	mv	a0,s1
    80005274:	ffffc097          	auipc	ra,0xffffc
    80005278:	a16080e7          	jalr	-1514(ra) # 80000c8a <release>
      return -1;
    8000527c:	59fd                	li	s3,-1
    8000527e:	bff9                	j	8000525c <piperead+0xca>

0000000080005280 <flags2perm>:
#include "elf.h"

static int loadseg(pde_t *, uint64, struct inode *, uint, uint);

int flags2perm(int flags)
{
    80005280:	1141                	addi	sp,sp,-16
    80005282:	e422                	sd	s0,8(sp)
    80005284:	0800                	addi	s0,sp,16
    80005286:	87aa                	mv	a5,a0
    int perm = 0;
    if(flags & 0x1)
    80005288:	8905                	andi	a0,a0,1
    8000528a:	050e                	slli	a0,a0,0x3
      perm = PTE_X;
    if(flags & 0x2)
    8000528c:	8b89                	andi	a5,a5,2
    8000528e:	c399                	beqz	a5,80005294 <flags2perm+0x14>
      perm |= PTE_W;
    80005290:	00456513          	ori	a0,a0,4
    return perm;
}
    80005294:	6422                	ld	s0,8(sp)
    80005296:	0141                	addi	sp,sp,16
    80005298:	8082                	ret

000000008000529a <exec>:

int
exec(char *path, char **argv)
{
    8000529a:	de010113          	addi	sp,sp,-544
    8000529e:	20113c23          	sd	ra,536(sp)
    800052a2:	20813823          	sd	s0,528(sp)
    800052a6:	20913423          	sd	s1,520(sp)
    800052aa:	21213023          	sd	s2,512(sp)
    800052ae:	ffce                	sd	s3,504(sp)
    800052b0:	fbd2                	sd	s4,496(sp)
    800052b2:	f7d6                	sd	s5,488(sp)
    800052b4:	f3da                	sd	s6,480(sp)
    800052b6:	efde                	sd	s7,472(sp)
    800052b8:	ebe2                	sd	s8,464(sp)
    800052ba:	e7e6                	sd	s9,456(sp)
    800052bc:	e3ea                	sd	s10,448(sp)
    800052be:	ff6e                	sd	s11,440(sp)
    800052c0:	1400                	addi	s0,sp,544
    800052c2:	892a                	mv	s2,a0
    800052c4:	dea43423          	sd	a0,-536(s0)
    800052c8:	deb43823          	sd	a1,-528(s0)
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
  struct elfhdr elf;
  struct inode *ip;
  struct proghdr ph;
  pagetable_t pagetable = 0, oldpagetable;
  struct proc *p = myproc();
    800052cc:	ffffc097          	auipc	ra,0xffffc
    800052d0:	6e0080e7          	jalr	1760(ra) # 800019ac <myproc>
    800052d4:	84aa                	mv	s1,a0

  begin_op();
    800052d6:	fffff097          	auipc	ra,0xfffff
    800052da:	482080e7          	jalr	1154(ra) # 80004758 <begin_op>

  if((ip = namei(path)) == 0){
    800052de:	854a                	mv	a0,s2
    800052e0:	fffff097          	auipc	ra,0xfffff
    800052e4:	258080e7          	jalr	600(ra) # 80004538 <namei>
    800052e8:	c93d                	beqz	a0,8000535e <exec+0xc4>
    800052ea:	8aaa                	mv	s5,a0
    end_op();
    return -1;
  }
  ilock(ip);
    800052ec:	fffff097          	auipc	ra,0xfffff
    800052f0:	aa0080e7          	jalr	-1376(ra) # 80003d8c <ilock>

  // Check ELF header
  if(readi(ip, 0, (uint64)&elf, 0, sizeof(elf)) != sizeof(elf))
    800052f4:	04000713          	li	a4,64
    800052f8:	4681                	li	a3,0
    800052fa:	e5040613          	addi	a2,s0,-432
    800052fe:	4581                	li	a1,0
    80005300:	8556                	mv	a0,s5
    80005302:	fffff097          	auipc	ra,0xfffff
    80005306:	d3e080e7          	jalr	-706(ra) # 80004040 <readi>
    8000530a:	04000793          	li	a5,64
    8000530e:	00f51a63          	bne	a0,a5,80005322 <exec+0x88>
    goto bad;

  if(elf.magic != ELF_MAGIC)
    80005312:	e5042703          	lw	a4,-432(s0)
    80005316:	464c47b7          	lui	a5,0x464c4
    8000531a:	57f78793          	addi	a5,a5,1407 # 464c457f <_entry-0x39b3ba81>
    8000531e:	04f70663          	beq	a4,a5,8000536a <exec+0xd0>

 bad:
  if(pagetable)
    proc_freepagetable(pagetable, sz);
  if(ip){
    iunlockput(ip);
    80005322:	8556                	mv	a0,s5
    80005324:	fffff097          	auipc	ra,0xfffff
    80005328:	cca080e7          	jalr	-822(ra) # 80003fee <iunlockput>
    end_op();
    8000532c:	fffff097          	auipc	ra,0xfffff
    80005330:	4aa080e7          	jalr	1194(ra) # 800047d6 <end_op>
  }
  return -1;
    80005334:	557d                	li	a0,-1
}
    80005336:	21813083          	ld	ra,536(sp)
    8000533a:	21013403          	ld	s0,528(sp)
    8000533e:	20813483          	ld	s1,520(sp)
    80005342:	20013903          	ld	s2,512(sp)
    80005346:	79fe                	ld	s3,504(sp)
    80005348:	7a5e                	ld	s4,496(sp)
    8000534a:	7abe                	ld	s5,488(sp)
    8000534c:	7b1e                	ld	s6,480(sp)
    8000534e:	6bfe                	ld	s7,472(sp)
    80005350:	6c5e                	ld	s8,464(sp)
    80005352:	6cbe                	ld	s9,456(sp)
    80005354:	6d1e                	ld	s10,448(sp)
    80005356:	7dfa                	ld	s11,440(sp)
    80005358:	22010113          	addi	sp,sp,544
    8000535c:	8082                	ret
    end_op();
    8000535e:	fffff097          	auipc	ra,0xfffff
    80005362:	478080e7          	jalr	1144(ra) # 800047d6 <end_op>
    return -1;
    80005366:	557d                	li	a0,-1
    80005368:	b7f9                	j	80005336 <exec+0x9c>
  if((pagetable = proc_pagetable(p)) == 0)
    8000536a:	8526                	mv	a0,s1
    8000536c:	ffffc097          	auipc	ra,0xffffc
    80005370:	704080e7          	jalr	1796(ra) # 80001a70 <proc_pagetable>
    80005374:	8b2a                	mv	s6,a0
    80005376:	d555                	beqz	a0,80005322 <exec+0x88>
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80005378:	e7042783          	lw	a5,-400(s0)
    8000537c:	e8845703          	lhu	a4,-376(s0)
    80005380:	c735                	beqz	a4,800053ec <exec+0x152>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    80005382:	4901                	li	s2,0
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80005384:	e0043423          	sd	zero,-504(s0)
    if(ph.vaddr % PGSIZE != 0)
    80005388:	6a05                	lui	s4,0x1
    8000538a:	fffa0713          	addi	a4,s4,-1 # fff <_entry-0x7ffff001>
    8000538e:	dee43023          	sd	a4,-544(s0)
loadseg(pagetable_t pagetable, uint64 va, struct inode *ip, uint offset, uint sz)
{
  uint i, n;
  uint64 pa;

  for(i = 0; i < sz; i += PGSIZE){
    80005392:	6d85                	lui	s11,0x1
    80005394:	7d7d                	lui	s10,0xfffff
    80005396:	ac3d                	j	800055d4 <exec+0x33a>
    pa = walkaddr(pagetable, va + i);
    if(pa == 0)
      panic("loadseg: address should exist");
    80005398:	00003517          	auipc	a0,0x3
    8000539c:	35850513          	addi	a0,a0,856 # 800086f0 <syscalls+0x2a0>
    800053a0:	ffffb097          	auipc	ra,0xffffb
    800053a4:	1a0080e7          	jalr	416(ra) # 80000540 <panic>
    if(sz - i < PGSIZE)
      n = sz - i;
    else
      n = PGSIZE;
    if(readi(ip, 0, (uint64)pa, offset+i, n) != n)
    800053a8:	874a                	mv	a4,s2
    800053aa:	009c86bb          	addw	a3,s9,s1
    800053ae:	4581                	li	a1,0
    800053b0:	8556                	mv	a0,s5
    800053b2:	fffff097          	auipc	ra,0xfffff
    800053b6:	c8e080e7          	jalr	-882(ra) # 80004040 <readi>
    800053ba:	2501                	sext.w	a0,a0
    800053bc:	1aa91963          	bne	s2,a0,8000556e <exec+0x2d4>
  for(i = 0; i < sz; i += PGSIZE){
    800053c0:	009d84bb          	addw	s1,s11,s1
    800053c4:	013d09bb          	addw	s3,s10,s3
    800053c8:	1f74f663          	bgeu	s1,s7,800055b4 <exec+0x31a>
    pa = walkaddr(pagetable, va + i);
    800053cc:	02049593          	slli	a1,s1,0x20
    800053d0:	9181                	srli	a1,a1,0x20
    800053d2:	95e2                	add	a1,a1,s8
    800053d4:	855a                	mv	a0,s6
    800053d6:	ffffc097          	auipc	ra,0xffffc
    800053da:	c86080e7          	jalr	-890(ra) # 8000105c <walkaddr>
    800053de:	862a                	mv	a2,a0
    if(pa == 0)
    800053e0:	dd45                	beqz	a0,80005398 <exec+0xfe>
      n = PGSIZE;
    800053e2:	8952                	mv	s2,s4
    if(sz - i < PGSIZE)
    800053e4:	fd49f2e3          	bgeu	s3,s4,800053a8 <exec+0x10e>
      n = sz - i;
    800053e8:	894e                	mv	s2,s3
    800053ea:	bf7d                	j	800053a8 <exec+0x10e>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    800053ec:	4901                	li	s2,0
  iunlockput(ip);
    800053ee:	8556                	mv	a0,s5
    800053f0:	fffff097          	auipc	ra,0xfffff
    800053f4:	bfe080e7          	jalr	-1026(ra) # 80003fee <iunlockput>
  end_op();
    800053f8:	fffff097          	auipc	ra,0xfffff
    800053fc:	3de080e7          	jalr	990(ra) # 800047d6 <end_op>
  p = myproc();
    80005400:	ffffc097          	auipc	ra,0xffffc
    80005404:	5ac080e7          	jalr	1452(ra) # 800019ac <myproc>
    80005408:	8baa                	mv	s7,a0
  uint64 oldsz = p->sz;
    8000540a:	06853d03          	ld	s10,104(a0)
  sz = PGROUNDUP(sz);
    8000540e:	6785                	lui	a5,0x1
    80005410:	17fd                	addi	a5,a5,-1 # fff <_entry-0x7ffff001>
    80005412:	97ca                	add	a5,a5,s2
    80005414:	777d                	lui	a4,0xfffff
    80005416:	8ff9                	and	a5,a5,a4
    80005418:	def43c23          	sd	a5,-520(s0)
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE, PTE_W)) == 0)
    8000541c:	4691                	li	a3,4
    8000541e:	6609                	lui	a2,0x2
    80005420:	963e                	add	a2,a2,a5
    80005422:	85be                	mv	a1,a5
    80005424:	855a                	mv	a0,s6
    80005426:	ffffc097          	auipc	ra,0xffffc
    8000542a:	fea080e7          	jalr	-22(ra) # 80001410 <uvmalloc>
    8000542e:	8c2a                	mv	s8,a0
  ip = 0;
    80005430:	4a81                	li	s5,0
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE, PTE_W)) == 0)
    80005432:	12050e63          	beqz	a0,8000556e <exec+0x2d4>
  uvmclear(pagetable, sz-2*PGSIZE);
    80005436:	75f9                	lui	a1,0xffffe
    80005438:	95aa                	add	a1,a1,a0
    8000543a:	855a                	mv	a0,s6
    8000543c:	ffffc097          	auipc	ra,0xffffc
    80005440:	1fe080e7          	jalr	510(ra) # 8000163a <uvmclear>
  stackbase = sp - PGSIZE;
    80005444:	7afd                	lui	s5,0xfffff
    80005446:	9ae2                	add	s5,s5,s8
  for(argc = 0; argv[argc]; argc++) {
    80005448:	df043783          	ld	a5,-528(s0)
    8000544c:	6388                	ld	a0,0(a5)
    8000544e:	c925                	beqz	a0,800054be <exec+0x224>
    80005450:	e9040993          	addi	s3,s0,-368
    80005454:	f9040c93          	addi	s9,s0,-112
  sp = sz;
    80005458:	8962                	mv	s2,s8
  for(argc = 0; argv[argc]; argc++) {
    8000545a:	4481                	li	s1,0
    sp -= strlen(argv[argc]) + 1;
    8000545c:	ffffc097          	auipc	ra,0xffffc
    80005460:	9f2080e7          	jalr	-1550(ra) # 80000e4e <strlen>
    80005464:	0015079b          	addiw	a5,a0,1
    80005468:	40f907b3          	sub	a5,s2,a5
    sp -= sp % 16; // riscv sp must be 16-byte aligned
    8000546c:	ff07f913          	andi	s2,a5,-16
    if(sp < stackbase)
    80005470:	13596663          	bltu	s2,s5,8000559c <exec+0x302>
    if(copyout(pagetable, sp, argv[argc], strlen(argv[argc]) + 1) < 0)
    80005474:	df043d83          	ld	s11,-528(s0)
    80005478:	000dba03          	ld	s4,0(s11) # 1000 <_entry-0x7ffff000>
    8000547c:	8552                	mv	a0,s4
    8000547e:	ffffc097          	auipc	ra,0xffffc
    80005482:	9d0080e7          	jalr	-1584(ra) # 80000e4e <strlen>
    80005486:	0015069b          	addiw	a3,a0,1
    8000548a:	8652                	mv	a2,s4
    8000548c:	85ca                	mv	a1,s2
    8000548e:	855a                	mv	a0,s6
    80005490:	ffffc097          	auipc	ra,0xffffc
    80005494:	1dc080e7          	jalr	476(ra) # 8000166c <copyout>
    80005498:	10054663          	bltz	a0,800055a4 <exec+0x30a>
    ustack[argc] = sp;
    8000549c:	0129b023          	sd	s2,0(s3)
  for(argc = 0; argv[argc]; argc++) {
    800054a0:	0485                	addi	s1,s1,1
    800054a2:	008d8793          	addi	a5,s11,8
    800054a6:	def43823          	sd	a5,-528(s0)
    800054aa:	008db503          	ld	a0,8(s11)
    800054ae:	c911                	beqz	a0,800054c2 <exec+0x228>
    if(argc >= MAXARG)
    800054b0:	09a1                	addi	s3,s3,8
    800054b2:	fb3c95e3          	bne	s9,s3,8000545c <exec+0x1c2>
  sz = sz1;
    800054b6:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    800054ba:	4a81                	li	s5,0
    800054bc:	a84d                	j	8000556e <exec+0x2d4>
  sp = sz;
    800054be:	8962                	mv	s2,s8
  for(argc = 0; argv[argc]; argc++) {
    800054c0:	4481                	li	s1,0
  ustack[argc] = 0;
    800054c2:	00349793          	slli	a5,s1,0x3
    800054c6:	f9078793          	addi	a5,a5,-112
    800054ca:	97a2                	add	a5,a5,s0
    800054cc:	f007b023          	sd	zero,-256(a5)
  sp -= (argc+1) * sizeof(uint64);
    800054d0:	00148693          	addi	a3,s1,1
    800054d4:	068e                	slli	a3,a3,0x3
    800054d6:	40d90933          	sub	s2,s2,a3
  sp -= sp % 16;
    800054da:	ff097913          	andi	s2,s2,-16
  if(sp < stackbase)
    800054de:	01597663          	bgeu	s2,s5,800054ea <exec+0x250>
  sz = sz1;
    800054e2:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    800054e6:	4a81                	li	s5,0
    800054e8:	a059                	j	8000556e <exec+0x2d4>
  if(copyout(pagetable, sp, (char *)ustack, (argc+1)*sizeof(uint64)) < 0)
    800054ea:	e9040613          	addi	a2,s0,-368
    800054ee:	85ca                	mv	a1,s2
    800054f0:	855a                	mv	a0,s6
    800054f2:	ffffc097          	auipc	ra,0xffffc
    800054f6:	17a080e7          	jalr	378(ra) # 8000166c <copyout>
    800054fa:	0a054963          	bltz	a0,800055ac <exec+0x312>
  p->trapframe->a1 = sp;
    800054fe:	078bb783          	ld	a5,120(s7)
    80005502:	0727bc23          	sd	s2,120(a5)
  for(last=s=path; *s; s++)
    80005506:	de843783          	ld	a5,-536(s0)
    8000550a:	0007c703          	lbu	a4,0(a5)
    8000550e:	cf11                	beqz	a4,8000552a <exec+0x290>
    80005510:	0785                	addi	a5,a5,1
    if(*s == '/')
    80005512:	02f00693          	li	a3,47
    80005516:	a039                	j	80005524 <exec+0x28a>
      last = s+1;
    80005518:	def43423          	sd	a5,-536(s0)
  for(last=s=path; *s; s++)
    8000551c:	0785                	addi	a5,a5,1
    8000551e:	fff7c703          	lbu	a4,-1(a5)
    80005522:	c701                	beqz	a4,8000552a <exec+0x290>
    if(*s == '/')
    80005524:	fed71ce3          	bne	a4,a3,8000551c <exec+0x282>
    80005528:	bfc5                	j	80005518 <exec+0x27e>
  safestrcpy(p->name, last, sizeof(p->name));
    8000552a:	4641                	li	a2,16
    8000552c:	de843583          	ld	a1,-536(s0)
    80005530:	178b8513          	addi	a0,s7,376
    80005534:	ffffc097          	auipc	ra,0xffffc
    80005538:	8e8080e7          	jalr	-1816(ra) # 80000e1c <safestrcpy>
  oldpagetable = p->pagetable;
    8000553c:	070bb503          	ld	a0,112(s7)
  p->pagetable = pagetable;
    80005540:	076bb823          	sd	s6,112(s7)
  p->sz = sz;
    80005544:	078bb423          	sd	s8,104(s7)
  p->trapframe->epc = elf.entry;  // initial program counter = main
    80005548:	078bb783          	ld	a5,120(s7)
    8000554c:	e6843703          	ld	a4,-408(s0)
    80005550:	ef98                	sd	a4,24(a5)
  p->trapframe->sp = sp; // initial stack pointer
    80005552:	078bb783          	ld	a5,120(s7)
    80005556:	0327b823          	sd	s2,48(a5)
  proc_freepagetable(oldpagetable, oldsz);
    8000555a:	85ea                	mv	a1,s10
    8000555c:	ffffc097          	auipc	ra,0xffffc
    80005560:	5b0080e7          	jalr	1456(ra) # 80001b0c <proc_freepagetable>
  return argc; // this ends up in a0, the first argument to main(argc, argv)
    80005564:	0004851b          	sext.w	a0,s1
    80005568:	b3f9                	j	80005336 <exec+0x9c>
    8000556a:	df243c23          	sd	s2,-520(s0)
    proc_freepagetable(pagetable, sz);
    8000556e:	df843583          	ld	a1,-520(s0)
    80005572:	855a                	mv	a0,s6
    80005574:	ffffc097          	auipc	ra,0xffffc
    80005578:	598080e7          	jalr	1432(ra) # 80001b0c <proc_freepagetable>
  if(ip){
    8000557c:	da0a93e3          	bnez	s5,80005322 <exec+0x88>
  return -1;
    80005580:	557d                	li	a0,-1
    80005582:	bb55                	j	80005336 <exec+0x9c>
    80005584:	df243c23          	sd	s2,-520(s0)
    80005588:	b7dd                	j	8000556e <exec+0x2d4>
    8000558a:	df243c23          	sd	s2,-520(s0)
    8000558e:	b7c5                	j	8000556e <exec+0x2d4>
    80005590:	df243c23          	sd	s2,-520(s0)
    80005594:	bfe9                	j	8000556e <exec+0x2d4>
    80005596:	df243c23          	sd	s2,-520(s0)
    8000559a:	bfd1                	j	8000556e <exec+0x2d4>
  sz = sz1;
    8000559c:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    800055a0:	4a81                	li	s5,0
    800055a2:	b7f1                	j	8000556e <exec+0x2d4>
  sz = sz1;
    800055a4:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    800055a8:	4a81                	li	s5,0
    800055aa:	b7d1                	j	8000556e <exec+0x2d4>
  sz = sz1;
    800055ac:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    800055b0:	4a81                	li	s5,0
    800055b2:	bf75                	j	8000556e <exec+0x2d4>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz, flags2perm(ph.flags))) == 0)
    800055b4:	df843903          	ld	s2,-520(s0)
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    800055b8:	e0843783          	ld	a5,-504(s0)
    800055bc:	0017869b          	addiw	a3,a5,1
    800055c0:	e0d43423          	sd	a3,-504(s0)
    800055c4:	e0043783          	ld	a5,-512(s0)
    800055c8:	0387879b          	addiw	a5,a5,56
    800055cc:	e8845703          	lhu	a4,-376(s0)
    800055d0:	e0e6dfe3          	bge	a3,a4,800053ee <exec+0x154>
    if(readi(ip, 0, (uint64)&ph, off, sizeof(ph)) != sizeof(ph))
    800055d4:	2781                	sext.w	a5,a5
    800055d6:	e0f43023          	sd	a5,-512(s0)
    800055da:	03800713          	li	a4,56
    800055de:	86be                	mv	a3,a5
    800055e0:	e1840613          	addi	a2,s0,-488
    800055e4:	4581                	li	a1,0
    800055e6:	8556                	mv	a0,s5
    800055e8:	fffff097          	auipc	ra,0xfffff
    800055ec:	a58080e7          	jalr	-1448(ra) # 80004040 <readi>
    800055f0:	03800793          	li	a5,56
    800055f4:	f6f51be3          	bne	a0,a5,8000556a <exec+0x2d0>
    if(ph.type != ELF_PROG_LOAD)
    800055f8:	e1842783          	lw	a5,-488(s0)
    800055fc:	4705                	li	a4,1
    800055fe:	fae79de3          	bne	a5,a4,800055b8 <exec+0x31e>
    if(ph.memsz < ph.filesz)
    80005602:	e4043483          	ld	s1,-448(s0)
    80005606:	e3843783          	ld	a5,-456(s0)
    8000560a:	f6f4ede3          	bltu	s1,a5,80005584 <exec+0x2ea>
    if(ph.vaddr + ph.memsz < ph.vaddr)
    8000560e:	e2843783          	ld	a5,-472(s0)
    80005612:	94be                	add	s1,s1,a5
    80005614:	f6f4ebe3          	bltu	s1,a5,8000558a <exec+0x2f0>
    if(ph.vaddr % PGSIZE != 0)
    80005618:	de043703          	ld	a4,-544(s0)
    8000561c:	8ff9                	and	a5,a5,a4
    8000561e:	fbad                	bnez	a5,80005590 <exec+0x2f6>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz, flags2perm(ph.flags))) == 0)
    80005620:	e1c42503          	lw	a0,-484(s0)
    80005624:	00000097          	auipc	ra,0x0
    80005628:	c5c080e7          	jalr	-932(ra) # 80005280 <flags2perm>
    8000562c:	86aa                	mv	a3,a0
    8000562e:	8626                	mv	a2,s1
    80005630:	85ca                	mv	a1,s2
    80005632:	855a                	mv	a0,s6
    80005634:	ffffc097          	auipc	ra,0xffffc
    80005638:	ddc080e7          	jalr	-548(ra) # 80001410 <uvmalloc>
    8000563c:	dea43c23          	sd	a0,-520(s0)
    80005640:	d939                	beqz	a0,80005596 <exec+0x2fc>
    if(loadseg(pagetable, ph.vaddr, ip, ph.off, ph.filesz) < 0)
    80005642:	e2843c03          	ld	s8,-472(s0)
    80005646:	e2042c83          	lw	s9,-480(s0)
    8000564a:	e3842b83          	lw	s7,-456(s0)
  for(i = 0; i < sz; i += PGSIZE){
    8000564e:	f60b83e3          	beqz	s7,800055b4 <exec+0x31a>
    80005652:	89de                	mv	s3,s7
    80005654:	4481                	li	s1,0
    80005656:	bb9d                	j	800053cc <exec+0x132>

0000000080005658 <argfd>:

// Fetch the nth word-sized system call argument as a file descriptor
// and return both the descriptor and the corresponding struct file.
static int
argfd(int n, int *pfd, struct file **pf)
{
    80005658:	7179                	addi	sp,sp,-48
    8000565a:	f406                	sd	ra,40(sp)
    8000565c:	f022                	sd	s0,32(sp)
    8000565e:	ec26                	sd	s1,24(sp)
    80005660:	e84a                	sd	s2,16(sp)
    80005662:	1800                	addi	s0,sp,48
    80005664:	892e                	mv	s2,a1
    80005666:	84b2                	mv	s1,a2
  int fd;
  struct file *f;

  argint(n, &fd);
    80005668:	fdc40593          	addi	a1,s0,-36
    8000566c:	ffffe097          	auipc	ra,0xffffe
    80005670:	a2a080e7          	jalr	-1494(ra) # 80003096 <argint>
  if(fd < 0 || fd >= NOFILE || (f=myproc()->ofile[fd]) == 0)
    80005674:	fdc42703          	lw	a4,-36(s0)
    80005678:	47bd                	li	a5,15
    8000567a:	02e7eb63          	bltu	a5,a4,800056b0 <argfd+0x58>
    8000567e:	ffffc097          	auipc	ra,0xffffc
    80005682:	32e080e7          	jalr	814(ra) # 800019ac <myproc>
    80005686:	fdc42703          	lw	a4,-36(s0)
    8000568a:	01e70793          	addi	a5,a4,30 # fffffffffffff01e <end+0xffffffff7ffdc49e>
    8000568e:	078e                	slli	a5,a5,0x3
    80005690:	953e                	add	a0,a0,a5
    80005692:	611c                	ld	a5,0(a0)
    80005694:	c385                	beqz	a5,800056b4 <argfd+0x5c>
    return -1;
  if(pfd)
    80005696:	00090463          	beqz	s2,8000569e <argfd+0x46>
    *pfd = fd;
    8000569a:	00e92023          	sw	a4,0(s2)
  if(pf)
    *pf = f;
  return 0;
    8000569e:	4501                	li	a0,0
  if(pf)
    800056a0:	c091                	beqz	s1,800056a4 <argfd+0x4c>
    *pf = f;
    800056a2:	e09c                	sd	a5,0(s1)
}
    800056a4:	70a2                	ld	ra,40(sp)
    800056a6:	7402                	ld	s0,32(sp)
    800056a8:	64e2                	ld	s1,24(sp)
    800056aa:	6942                	ld	s2,16(sp)
    800056ac:	6145                	addi	sp,sp,48
    800056ae:	8082                	ret
    return -1;
    800056b0:	557d                	li	a0,-1
    800056b2:	bfcd                	j	800056a4 <argfd+0x4c>
    800056b4:	557d                	li	a0,-1
    800056b6:	b7fd                	j	800056a4 <argfd+0x4c>

00000000800056b8 <fdalloc>:

// Allocate a file descriptor for the given file.
// Takes over file reference from caller on success.
static int
fdalloc(struct file *f)
{
    800056b8:	1101                	addi	sp,sp,-32
    800056ba:	ec06                	sd	ra,24(sp)
    800056bc:	e822                	sd	s0,16(sp)
    800056be:	e426                	sd	s1,8(sp)
    800056c0:	1000                	addi	s0,sp,32
    800056c2:	84aa                	mv	s1,a0
  int fd;
  struct proc *p = myproc();
    800056c4:	ffffc097          	auipc	ra,0xffffc
    800056c8:	2e8080e7          	jalr	744(ra) # 800019ac <myproc>
    800056cc:	862a                	mv	a2,a0

  for(fd = 0; fd < NOFILE; fd++){
    800056ce:	0f050793          	addi	a5,a0,240
    800056d2:	4501                	li	a0,0
    800056d4:	46c1                	li	a3,16
    if(p->ofile[fd] == 0){
    800056d6:	6398                	ld	a4,0(a5)
    800056d8:	cb19                	beqz	a4,800056ee <fdalloc+0x36>
  for(fd = 0; fd < NOFILE; fd++){
    800056da:	2505                	addiw	a0,a0,1
    800056dc:	07a1                	addi	a5,a5,8
    800056de:	fed51ce3          	bne	a0,a3,800056d6 <fdalloc+0x1e>
      p->ofile[fd] = f;
      return fd;
    }
  }
  return -1;
    800056e2:	557d                	li	a0,-1
}
    800056e4:	60e2                	ld	ra,24(sp)
    800056e6:	6442                	ld	s0,16(sp)
    800056e8:	64a2                	ld	s1,8(sp)
    800056ea:	6105                	addi	sp,sp,32
    800056ec:	8082                	ret
      p->ofile[fd] = f;
    800056ee:	01e50793          	addi	a5,a0,30
    800056f2:	078e                	slli	a5,a5,0x3
    800056f4:	963e                	add	a2,a2,a5
    800056f6:	e204                	sd	s1,0(a2)
      return fd;
    800056f8:	b7f5                	j	800056e4 <fdalloc+0x2c>

00000000800056fa <create>:
  return -1;
}

static struct inode*
create(char *path, short type, short major, short minor)
{
    800056fa:	715d                	addi	sp,sp,-80
    800056fc:	e486                	sd	ra,72(sp)
    800056fe:	e0a2                	sd	s0,64(sp)
    80005700:	fc26                	sd	s1,56(sp)
    80005702:	f84a                	sd	s2,48(sp)
    80005704:	f44e                	sd	s3,40(sp)
    80005706:	f052                	sd	s4,32(sp)
    80005708:	ec56                	sd	s5,24(sp)
    8000570a:	e85a                	sd	s6,16(sp)
    8000570c:	0880                	addi	s0,sp,80
    8000570e:	8b2e                	mv	s6,a1
    80005710:	89b2                	mv	s3,a2
    80005712:	8936                	mv	s2,a3
  struct inode *ip, *dp;
  char name[DIRSIZ];

  if((dp = nameiparent(path, name)) == 0)
    80005714:	fb040593          	addi	a1,s0,-80
    80005718:	fffff097          	auipc	ra,0xfffff
    8000571c:	e3e080e7          	jalr	-450(ra) # 80004556 <nameiparent>
    80005720:	84aa                	mv	s1,a0
    80005722:	14050f63          	beqz	a0,80005880 <create+0x186>
    return 0;

  ilock(dp);
    80005726:	ffffe097          	auipc	ra,0xffffe
    8000572a:	666080e7          	jalr	1638(ra) # 80003d8c <ilock>

  if((ip = dirlookup(dp, name, 0)) != 0){
    8000572e:	4601                	li	a2,0
    80005730:	fb040593          	addi	a1,s0,-80
    80005734:	8526                	mv	a0,s1
    80005736:	fffff097          	auipc	ra,0xfffff
    8000573a:	b3a080e7          	jalr	-1222(ra) # 80004270 <dirlookup>
    8000573e:	8aaa                	mv	s5,a0
    80005740:	c931                	beqz	a0,80005794 <create+0x9a>
    iunlockput(dp);
    80005742:	8526                	mv	a0,s1
    80005744:	fffff097          	auipc	ra,0xfffff
    80005748:	8aa080e7          	jalr	-1878(ra) # 80003fee <iunlockput>
    ilock(ip);
    8000574c:	8556                	mv	a0,s5
    8000574e:	ffffe097          	auipc	ra,0xffffe
    80005752:	63e080e7          	jalr	1598(ra) # 80003d8c <ilock>
    if(type == T_FILE && (ip->type == T_FILE || ip->type == T_DEVICE))
    80005756:	000b059b          	sext.w	a1,s6
    8000575a:	4789                	li	a5,2
    8000575c:	02f59563          	bne	a1,a5,80005786 <create+0x8c>
    80005760:	044ad783          	lhu	a5,68(s5) # fffffffffffff044 <end+0xffffffff7ffdc4c4>
    80005764:	37f9                	addiw	a5,a5,-2
    80005766:	17c2                	slli	a5,a5,0x30
    80005768:	93c1                	srli	a5,a5,0x30
    8000576a:	4705                	li	a4,1
    8000576c:	00f76d63          	bltu	a4,a5,80005786 <create+0x8c>
  ip->nlink = 0;
  iupdate(ip);
  iunlockput(ip);
  iunlockput(dp);
  return 0;
}
    80005770:	8556                	mv	a0,s5
    80005772:	60a6                	ld	ra,72(sp)
    80005774:	6406                	ld	s0,64(sp)
    80005776:	74e2                	ld	s1,56(sp)
    80005778:	7942                	ld	s2,48(sp)
    8000577a:	79a2                	ld	s3,40(sp)
    8000577c:	7a02                	ld	s4,32(sp)
    8000577e:	6ae2                	ld	s5,24(sp)
    80005780:	6b42                	ld	s6,16(sp)
    80005782:	6161                	addi	sp,sp,80
    80005784:	8082                	ret
    iunlockput(ip);
    80005786:	8556                	mv	a0,s5
    80005788:	fffff097          	auipc	ra,0xfffff
    8000578c:	866080e7          	jalr	-1946(ra) # 80003fee <iunlockput>
    return 0;
    80005790:	4a81                	li	s5,0
    80005792:	bff9                	j	80005770 <create+0x76>
  if((ip = ialloc(dp->dev, type)) == 0){
    80005794:	85da                	mv	a1,s6
    80005796:	4088                	lw	a0,0(s1)
    80005798:	ffffe097          	auipc	ra,0xffffe
    8000579c:	456080e7          	jalr	1110(ra) # 80003bee <ialloc>
    800057a0:	8a2a                	mv	s4,a0
    800057a2:	c539                	beqz	a0,800057f0 <create+0xf6>
  ilock(ip);
    800057a4:	ffffe097          	auipc	ra,0xffffe
    800057a8:	5e8080e7          	jalr	1512(ra) # 80003d8c <ilock>
  ip->major = major;
    800057ac:	053a1323          	sh	s3,70(s4)
  ip->minor = minor;
    800057b0:	052a1423          	sh	s2,72(s4)
  ip->nlink = 1;
    800057b4:	4905                	li	s2,1
    800057b6:	052a1523          	sh	s2,74(s4)
  iupdate(ip);
    800057ba:	8552                	mv	a0,s4
    800057bc:	ffffe097          	auipc	ra,0xffffe
    800057c0:	504080e7          	jalr	1284(ra) # 80003cc0 <iupdate>
  if(type == T_DIR){  // Create . and .. entries.
    800057c4:	000b059b          	sext.w	a1,s6
    800057c8:	03258b63          	beq	a1,s2,800057fe <create+0x104>
  if(dirlink(dp, name, ip->inum) < 0)
    800057cc:	004a2603          	lw	a2,4(s4)
    800057d0:	fb040593          	addi	a1,s0,-80
    800057d4:	8526                	mv	a0,s1
    800057d6:	fffff097          	auipc	ra,0xfffff
    800057da:	cb0080e7          	jalr	-848(ra) # 80004486 <dirlink>
    800057de:	06054f63          	bltz	a0,8000585c <create+0x162>
  iunlockput(dp);
    800057e2:	8526                	mv	a0,s1
    800057e4:	fffff097          	auipc	ra,0xfffff
    800057e8:	80a080e7          	jalr	-2038(ra) # 80003fee <iunlockput>
  return ip;
    800057ec:	8ad2                	mv	s5,s4
    800057ee:	b749                	j	80005770 <create+0x76>
    iunlockput(dp);
    800057f0:	8526                	mv	a0,s1
    800057f2:	ffffe097          	auipc	ra,0xffffe
    800057f6:	7fc080e7          	jalr	2044(ra) # 80003fee <iunlockput>
    return 0;
    800057fa:	8ad2                	mv	s5,s4
    800057fc:	bf95                	j	80005770 <create+0x76>
    if(dirlink(ip, ".", ip->inum) < 0 || dirlink(ip, "..", dp->inum) < 0)
    800057fe:	004a2603          	lw	a2,4(s4)
    80005802:	00003597          	auipc	a1,0x3
    80005806:	f0e58593          	addi	a1,a1,-242 # 80008710 <syscalls+0x2c0>
    8000580a:	8552                	mv	a0,s4
    8000580c:	fffff097          	auipc	ra,0xfffff
    80005810:	c7a080e7          	jalr	-902(ra) # 80004486 <dirlink>
    80005814:	04054463          	bltz	a0,8000585c <create+0x162>
    80005818:	40d0                	lw	a2,4(s1)
    8000581a:	00003597          	auipc	a1,0x3
    8000581e:	efe58593          	addi	a1,a1,-258 # 80008718 <syscalls+0x2c8>
    80005822:	8552                	mv	a0,s4
    80005824:	fffff097          	auipc	ra,0xfffff
    80005828:	c62080e7          	jalr	-926(ra) # 80004486 <dirlink>
    8000582c:	02054863          	bltz	a0,8000585c <create+0x162>
  if(dirlink(dp, name, ip->inum) < 0)
    80005830:	004a2603          	lw	a2,4(s4)
    80005834:	fb040593          	addi	a1,s0,-80
    80005838:	8526                	mv	a0,s1
    8000583a:	fffff097          	auipc	ra,0xfffff
    8000583e:	c4c080e7          	jalr	-948(ra) # 80004486 <dirlink>
    80005842:	00054d63          	bltz	a0,8000585c <create+0x162>
    dp->nlink++;  // for ".."
    80005846:	04a4d783          	lhu	a5,74(s1)
    8000584a:	2785                	addiw	a5,a5,1
    8000584c:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    80005850:	8526                	mv	a0,s1
    80005852:	ffffe097          	auipc	ra,0xffffe
    80005856:	46e080e7          	jalr	1134(ra) # 80003cc0 <iupdate>
    8000585a:	b761                	j	800057e2 <create+0xe8>
  ip->nlink = 0;
    8000585c:	040a1523          	sh	zero,74(s4)
  iupdate(ip);
    80005860:	8552                	mv	a0,s4
    80005862:	ffffe097          	auipc	ra,0xffffe
    80005866:	45e080e7          	jalr	1118(ra) # 80003cc0 <iupdate>
  iunlockput(ip);
    8000586a:	8552                	mv	a0,s4
    8000586c:	ffffe097          	auipc	ra,0xffffe
    80005870:	782080e7          	jalr	1922(ra) # 80003fee <iunlockput>
  iunlockput(dp);
    80005874:	8526                	mv	a0,s1
    80005876:	ffffe097          	auipc	ra,0xffffe
    8000587a:	778080e7          	jalr	1912(ra) # 80003fee <iunlockput>
  return 0;
    8000587e:	bdcd                	j	80005770 <create+0x76>
    return 0;
    80005880:	8aaa                	mv	s5,a0
    80005882:	b5fd                	j	80005770 <create+0x76>

0000000080005884 <sys_dup>:
{
    80005884:	7179                	addi	sp,sp,-48
    80005886:	f406                	sd	ra,40(sp)
    80005888:	f022                	sd	s0,32(sp)
    8000588a:	ec26                	sd	s1,24(sp)
    8000588c:	e84a                	sd	s2,16(sp)
    8000588e:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0)
    80005890:	fd840613          	addi	a2,s0,-40
    80005894:	4581                	li	a1,0
    80005896:	4501                	li	a0,0
    80005898:	00000097          	auipc	ra,0x0
    8000589c:	dc0080e7          	jalr	-576(ra) # 80005658 <argfd>
    return -1;
    800058a0:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0)
    800058a2:	02054363          	bltz	a0,800058c8 <sys_dup+0x44>
  if((fd=fdalloc(f)) < 0)
    800058a6:	fd843903          	ld	s2,-40(s0)
    800058aa:	854a                	mv	a0,s2
    800058ac:	00000097          	auipc	ra,0x0
    800058b0:	e0c080e7          	jalr	-500(ra) # 800056b8 <fdalloc>
    800058b4:	84aa                	mv	s1,a0
    return -1;
    800058b6:	57fd                	li	a5,-1
  if((fd=fdalloc(f)) < 0)
    800058b8:	00054863          	bltz	a0,800058c8 <sys_dup+0x44>
  filedup(f);
    800058bc:	854a                	mv	a0,s2
    800058be:	fffff097          	auipc	ra,0xfffff
    800058c2:	310080e7          	jalr	784(ra) # 80004bce <filedup>
  return fd;
    800058c6:	87a6                	mv	a5,s1
}
    800058c8:	853e                	mv	a0,a5
    800058ca:	70a2                	ld	ra,40(sp)
    800058cc:	7402                	ld	s0,32(sp)
    800058ce:	64e2                	ld	s1,24(sp)
    800058d0:	6942                	ld	s2,16(sp)
    800058d2:	6145                	addi	sp,sp,48
    800058d4:	8082                	ret

00000000800058d6 <sys_read>:
{
    800058d6:	7179                	addi	sp,sp,-48
    800058d8:	f406                	sd	ra,40(sp)
    800058da:	f022                	sd	s0,32(sp)
    800058dc:	1800                	addi	s0,sp,48
  argaddr(1, &p);
    800058de:	fd840593          	addi	a1,s0,-40
    800058e2:	4505                	li	a0,1
    800058e4:	ffffd097          	auipc	ra,0xffffd
    800058e8:	7d2080e7          	jalr	2002(ra) # 800030b6 <argaddr>
  argint(2, &n);
    800058ec:	fe440593          	addi	a1,s0,-28
    800058f0:	4509                	li	a0,2
    800058f2:	ffffd097          	auipc	ra,0xffffd
    800058f6:	7a4080e7          	jalr	1956(ra) # 80003096 <argint>
  if(argfd(0, 0, &f) < 0)
    800058fa:	fe840613          	addi	a2,s0,-24
    800058fe:	4581                	li	a1,0
    80005900:	4501                	li	a0,0
    80005902:	00000097          	auipc	ra,0x0
    80005906:	d56080e7          	jalr	-682(ra) # 80005658 <argfd>
    8000590a:	87aa                	mv	a5,a0
    return -1;
    8000590c:	557d                	li	a0,-1
  if(argfd(0, 0, &f) < 0)
    8000590e:	0007cc63          	bltz	a5,80005926 <sys_read+0x50>
  return fileread(f, p, n);
    80005912:	fe442603          	lw	a2,-28(s0)
    80005916:	fd843583          	ld	a1,-40(s0)
    8000591a:	fe843503          	ld	a0,-24(s0)
    8000591e:	fffff097          	auipc	ra,0xfffff
    80005922:	43c080e7          	jalr	1084(ra) # 80004d5a <fileread>
}
    80005926:	70a2                	ld	ra,40(sp)
    80005928:	7402                	ld	s0,32(sp)
    8000592a:	6145                	addi	sp,sp,48
    8000592c:	8082                	ret

000000008000592e <sys_write>:
{
    8000592e:	7179                	addi	sp,sp,-48
    80005930:	f406                	sd	ra,40(sp)
    80005932:	f022                	sd	s0,32(sp)
    80005934:	1800                	addi	s0,sp,48
  argaddr(1, &p);
    80005936:	fd840593          	addi	a1,s0,-40
    8000593a:	4505                	li	a0,1
    8000593c:	ffffd097          	auipc	ra,0xffffd
    80005940:	77a080e7          	jalr	1914(ra) # 800030b6 <argaddr>
  argint(2, &n);
    80005944:	fe440593          	addi	a1,s0,-28
    80005948:	4509                	li	a0,2
    8000594a:	ffffd097          	auipc	ra,0xffffd
    8000594e:	74c080e7          	jalr	1868(ra) # 80003096 <argint>
  if(argfd(0, 0, &f) < 0)
    80005952:	fe840613          	addi	a2,s0,-24
    80005956:	4581                	li	a1,0
    80005958:	4501                	li	a0,0
    8000595a:	00000097          	auipc	ra,0x0
    8000595e:	cfe080e7          	jalr	-770(ra) # 80005658 <argfd>
    80005962:	87aa                	mv	a5,a0
    return -1;
    80005964:	557d                	li	a0,-1
  if(argfd(0, 0, &f) < 0)
    80005966:	0007cc63          	bltz	a5,8000597e <sys_write+0x50>
  return filewrite(f, p, n);
    8000596a:	fe442603          	lw	a2,-28(s0)
    8000596e:	fd843583          	ld	a1,-40(s0)
    80005972:	fe843503          	ld	a0,-24(s0)
    80005976:	fffff097          	auipc	ra,0xfffff
    8000597a:	4a6080e7          	jalr	1190(ra) # 80004e1c <filewrite>
}
    8000597e:	70a2                	ld	ra,40(sp)
    80005980:	7402                	ld	s0,32(sp)
    80005982:	6145                	addi	sp,sp,48
    80005984:	8082                	ret

0000000080005986 <sys_close>:
{
    80005986:	1101                	addi	sp,sp,-32
    80005988:	ec06                	sd	ra,24(sp)
    8000598a:	e822                	sd	s0,16(sp)
    8000598c:	1000                	addi	s0,sp,32
  if(argfd(0, &fd, &f) < 0)
    8000598e:	fe040613          	addi	a2,s0,-32
    80005992:	fec40593          	addi	a1,s0,-20
    80005996:	4501                	li	a0,0
    80005998:	00000097          	auipc	ra,0x0
    8000599c:	cc0080e7          	jalr	-832(ra) # 80005658 <argfd>
    return -1;
    800059a0:	57fd                	li	a5,-1
  if(argfd(0, &fd, &f) < 0)
    800059a2:	02054463          	bltz	a0,800059ca <sys_close+0x44>
  myproc()->ofile[fd] = 0;
    800059a6:	ffffc097          	auipc	ra,0xffffc
    800059aa:	006080e7          	jalr	6(ra) # 800019ac <myproc>
    800059ae:	fec42783          	lw	a5,-20(s0)
    800059b2:	07f9                	addi	a5,a5,30
    800059b4:	078e                	slli	a5,a5,0x3
    800059b6:	953e                	add	a0,a0,a5
    800059b8:	00053023          	sd	zero,0(a0)
  fileclose(f);
    800059bc:	fe043503          	ld	a0,-32(s0)
    800059c0:	fffff097          	auipc	ra,0xfffff
    800059c4:	260080e7          	jalr	608(ra) # 80004c20 <fileclose>
  return 0;
    800059c8:	4781                	li	a5,0
}
    800059ca:	853e                	mv	a0,a5
    800059cc:	60e2                	ld	ra,24(sp)
    800059ce:	6442                	ld	s0,16(sp)
    800059d0:	6105                	addi	sp,sp,32
    800059d2:	8082                	ret

00000000800059d4 <sys_fstat>:
{
    800059d4:	1101                	addi	sp,sp,-32
    800059d6:	ec06                	sd	ra,24(sp)
    800059d8:	e822                	sd	s0,16(sp)
    800059da:	1000                	addi	s0,sp,32
  argaddr(1, &st);
    800059dc:	fe040593          	addi	a1,s0,-32
    800059e0:	4505                	li	a0,1
    800059e2:	ffffd097          	auipc	ra,0xffffd
    800059e6:	6d4080e7          	jalr	1748(ra) # 800030b6 <argaddr>
  if(argfd(0, 0, &f) < 0)
    800059ea:	fe840613          	addi	a2,s0,-24
    800059ee:	4581                	li	a1,0
    800059f0:	4501                	li	a0,0
    800059f2:	00000097          	auipc	ra,0x0
    800059f6:	c66080e7          	jalr	-922(ra) # 80005658 <argfd>
    800059fa:	87aa                	mv	a5,a0
    return -1;
    800059fc:	557d                	li	a0,-1
  if(argfd(0, 0, &f) < 0)
    800059fe:	0007ca63          	bltz	a5,80005a12 <sys_fstat+0x3e>
  return filestat(f, st);
    80005a02:	fe043583          	ld	a1,-32(s0)
    80005a06:	fe843503          	ld	a0,-24(s0)
    80005a0a:	fffff097          	auipc	ra,0xfffff
    80005a0e:	2de080e7          	jalr	734(ra) # 80004ce8 <filestat>
}
    80005a12:	60e2                	ld	ra,24(sp)
    80005a14:	6442                	ld	s0,16(sp)
    80005a16:	6105                	addi	sp,sp,32
    80005a18:	8082                	ret

0000000080005a1a <sys_link>:
{
    80005a1a:	7169                	addi	sp,sp,-304
    80005a1c:	f606                	sd	ra,296(sp)
    80005a1e:	f222                	sd	s0,288(sp)
    80005a20:	ee26                	sd	s1,280(sp)
    80005a22:	ea4a                	sd	s2,272(sp)
    80005a24:	1a00                	addi	s0,sp,304
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005a26:	08000613          	li	a2,128
    80005a2a:	ed040593          	addi	a1,s0,-304
    80005a2e:	4501                	li	a0,0
    80005a30:	ffffd097          	auipc	ra,0xffffd
    80005a34:	6a6080e7          	jalr	1702(ra) # 800030d6 <argstr>
    return -1;
    80005a38:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005a3a:	10054e63          	bltz	a0,80005b56 <sys_link+0x13c>
    80005a3e:	08000613          	li	a2,128
    80005a42:	f5040593          	addi	a1,s0,-176
    80005a46:	4505                	li	a0,1
    80005a48:	ffffd097          	auipc	ra,0xffffd
    80005a4c:	68e080e7          	jalr	1678(ra) # 800030d6 <argstr>
    return -1;
    80005a50:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005a52:	10054263          	bltz	a0,80005b56 <sys_link+0x13c>
  begin_op();
    80005a56:	fffff097          	auipc	ra,0xfffff
    80005a5a:	d02080e7          	jalr	-766(ra) # 80004758 <begin_op>
  if((ip = namei(old)) == 0){
    80005a5e:	ed040513          	addi	a0,s0,-304
    80005a62:	fffff097          	auipc	ra,0xfffff
    80005a66:	ad6080e7          	jalr	-1322(ra) # 80004538 <namei>
    80005a6a:	84aa                	mv	s1,a0
    80005a6c:	c551                	beqz	a0,80005af8 <sys_link+0xde>
  ilock(ip);
    80005a6e:	ffffe097          	auipc	ra,0xffffe
    80005a72:	31e080e7          	jalr	798(ra) # 80003d8c <ilock>
  if(ip->type == T_DIR){
    80005a76:	04449703          	lh	a4,68(s1)
    80005a7a:	4785                	li	a5,1
    80005a7c:	08f70463          	beq	a4,a5,80005b04 <sys_link+0xea>
  ip->nlink++;
    80005a80:	04a4d783          	lhu	a5,74(s1)
    80005a84:	2785                	addiw	a5,a5,1
    80005a86:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    80005a8a:	8526                	mv	a0,s1
    80005a8c:	ffffe097          	auipc	ra,0xffffe
    80005a90:	234080e7          	jalr	564(ra) # 80003cc0 <iupdate>
  iunlock(ip);
    80005a94:	8526                	mv	a0,s1
    80005a96:	ffffe097          	auipc	ra,0xffffe
    80005a9a:	3b8080e7          	jalr	952(ra) # 80003e4e <iunlock>
  if((dp = nameiparent(new, name)) == 0)
    80005a9e:	fd040593          	addi	a1,s0,-48
    80005aa2:	f5040513          	addi	a0,s0,-176
    80005aa6:	fffff097          	auipc	ra,0xfffff
    80005aaa:	ab0080e7          	jalr	-1360(ra) # 80004556 <nameiparent>
    80005aae:	892a                	mv	s2,a0
    80005ab0:	c935                	beqz	a0,80005b24 <sys_link+0x10a>
  ilock(dp);
    80005ab2:	ffffe097          	auipc	ra,0xffffe
    80005ab6:	2da080e7          	jalr	730(ra) # 80003d8c <ilock>
  if(dp->dev != ip->dev || dirlink(dp, name, ip->inum) < 0){
    80005aba:	00092703          	lw	a4,0(s2)
    80005abe:	409c                	lw	a5,0(s1)
    80005ac0:	04f71d63          	bne	a4,a5,80005b1a <sys_link+0x100>
    80005ac4:	40d0                	lw	a2,4(s1)
    80005ac6:	fd040593          	addi	a1,s0,-48
    80005aca:	854a                	mv	a0,s2
    80005acc:	fffff097          	auipc	ra,0xfffff
    80005ad0:	9ba080e7          	jalr	-1606(ra) # 80004486 <dirlink>
    80005ad4:	04054363          	bltz	a0,80005b1a <sys_link+0x100>
  iunlockput(dp);
    80005ad8:	854a                	mv	a0,s2
    80005ada:	ffffe097          	auipc	ra,0xffffe
    80005ade:	514080e7          	jalr	1300(ra) # 80003fee <iunlockput>
  iput(ip);
    80005ae2:	8526                	mv	a0,s1
    80005ae4:	ffffe097          	auipc	ra,0xffffe
    80005ae8:	462080e7          	jalr	1122(ra) # 80003f46 <iput>
  end_op();
    80005aec:	fffff097          	auipc	ra,0xfffff
    80005af0:	cea080e7          	jalr	-790(ra) # 800047d6 <end_op>
  return 0;
    80005af4:	4781                	li	a5,0
    80005af6:	a085                	j	80005b56 <sys_link+0x13c>
    end_op();
    80005af8:	fffff097          	auipc	ra,0xfffff
    80005afc:	cde080e7          	jalr	-802(ra) # 800047d6 <end_op>
    return -1;
    80005b00:	57fd                	li	a5,-1
    80005b02:	a891                	j	80005b56 <sys_link+0x13c>
    iunlockput(ip);
    80005b04:	8526                	mv	a0,s1
    80005b06:	ffffe097          	auipc	ra,0xffffe
    80005b0a:	4e8080e7          	jalr	1256(ra) # 80003fee <iunlockput>
    end_op();
    80005b0e:	fffff097          	auipc	ra,0xfffff
    80005b12:	cc8080e7          	jalr	-824(ra) # 800047d6 <end_op>
    return -1;
    80005b16:	57fd                	li	a5,-1
    80005b18:	a83d                	j	80005b56 <sys_link+0x13c>
    iunlockput(dp);
    80005b1a:	854a                	mv	a0,s2
    80005b1c:	ffffe097          	auipc	ra,0xffffe
    80005b20:	4d2080e7          	jalr	1234(ra) # 80003fee <iunlockput>
  ilock(ip);
    80005b24:	8526                	mv	a0,s1
    80005b26:	ffffe097          	auipc	ra,0xffffe
    80005b2a:	266080e7          	jalr	614(ra) # 80003d8c <ilock>
  ip->nlink--;
    80005b2e:	04a4d783          	lhu	a5,74(s1)
    80005b32:	37fd                	addiw	a5,a5,-1
    80005b34:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    80005b38:	8526                	mv	a0,s1
    80005b3a:	ffffe097          	auipc	ra,0xffffe
    80005b3e:	186080e7          	jalr	390(ra) # 80003cc0 <iupdate>
  iunlockput(ip);
    80005b42:	8526                	mv	a0,s1
    80005b44:	ffffe097          	auipc	ra,0xffffe
    80005b48:	4aa080e7          	jalr	1194(ra) # 80003fee <iunlockput>
  end_op();
    80005b4c:	fffff097          	auipc	ra,0xfffff
    80005b50:	c8a080e7          	jalr	-886(ra) # 800047d6 <end_op>
  return -1;
    80005b54:	57fd                	li	a5,-1
}
    80005b56:	853e                	mv	a0,a5
    80005b58:	70b2                	ld	ra,296(sp)
    80005b5a:	7412                	ld	s0,288(sp)
    80005b5c:	64f2                	ld	s1,280(sp)
    80005b5e:	6952                	ld	s2,272(sp)
    80005b60:	6155                	addi	sp,sp,304
    80005b62:	8082                	ret

0000000080005b64 <sys_unlink>:
{
    80005b64:	7151                	addi	sp,sp,-240
    80005b66:	f586                	sd	ra,232(sp)
    80005b68:	f1a2                	sd	s0,224(sp)
    80005b6a:	eda6                	sd	s1,216(sp)
    80005b6c:	e9ca                	sd	s2,208(sp)
    80005b6e:	e5ce                	sd	s3,200(sp)
    80005b70:	1980                	addi	s0,sp,240
  if(argstr(0, path, MAXPATH) < 0)
    80005b72:	08000613          	li	a2,128
    80005b76:	f3040593          	addi	a1,s0,-208
    80005b7a:	4501                	li	a0,0
    80005b7c:	ffffd097          	auipc	ra,0xffffd
    80005b80:	55a080e7          	jalr	1370(ra) # 800030d6 <argstr>
    80005b84:	18054163          	bltz	a0,80005d06 <sys_unlink+0x1a2>
  begin_op();
    80005b88:	fffff097          	auipc	ra,0xfffff
    80005b8c:	bd0080e7          	jalr	-1072(ra) # 80004758 <begin_op>
  if((dp = nameiparent(path, name)) == 0){
    80005b90:	fb040593          	addi	a1,s0,-80
    80005b94:	f3040513          	addi	a0,s0,-208
    80005b98:	fffff097          	auipc	ra,0xfffff
    80005b9c:	9be080e7          	jalr	-1602(ra) # 80004556 <nameiparent>
    80005ba0:	84aa                	mv	s1,a0
    80005ba2:	c979                	beqz	a0,80005c78 <sys_unlink+0x114>
  ilock(dp);
    80005ba4:	ffffe097          	auipc	ra,0xffffe
    80005ba8:	1e8080e7          	jalr	488(ra) # 80003d8c <ilock>
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
    80005bac:	00003597          	auipc	a1,0x3
    80005bb0:	b6458593          	addi	a1,a1,-1180 # 80008710 <syscalls+0x2c0>
    80005bb4:	fb040513          	addi	a0,s0,-80
    80005bb8:	ffffe097          	auipc	ra,0xffffe
    80005bbc:	69e080e7          	jalr	1694(ra) # 80004256 <namecmp>
    80005bc0:	14050a63          	beqz	a0,80005d14 <sys_unlink+0x1b0>
    80005bc4:	00003597          	auipc	a1,0x3
    80005bc8:	b5458593          	addi	a1,a1,-1196 # 80008718 <syscalls+0x2c8>
    80005bcc:	fb040513          	addi	a0,s0,-80
    80005bd0:	ffffe097          	auipc	ra,0xffffe
    80005bd4:	686080e7          	jalr	1670(ra) # 80004256 <namecmp>
    80005bd8:	12050e63          	beqz	a0,80005d14 <sys_unlink+0x1b0>
  if((ip = dirlookup(dp, name, &off)) == 0)
    80005bdc:	f2c40613          	addi	a2,s0,-212
    80005be0:	fb040593          	addi	a1,s0,-80
    80005be4:	8526                	mv	a0,s1
    80005be6:	ffffe097          	auipc	ra,0xffffe
    80005bea:	68a080e7          	jalr	1674(ra) # 80004270 <dirlookup>
    80005bee:	892a                	mv	s2,a0
    80005bf0:	12050263          	beqz	a0,80005d14 <sys_unlink+0x1b0>
  ilock(ip);
    80005bf4:	ffffe097          	auipc	ra,0xffffe
    80005bf8:	198080e7          	jalr	408(ra) # 80003d8c <ilock>
  if(ip->nlink < 1)
    80005bfc:	04a91783          	lh	a5,74(s2)
    80005c00:	08f05263          	blez	a5,80005c84 <sys_unlink+0x120>
  if(ip->type == T_DIR && !isdirempty(ip)){
    80005c04:	04491703          	lh	a4,68(s2)
    80005c08:	4785                	li	a5,1
    80005c0a:	08f70563          	beq	a4,a5,80005c94 <sys_unlink+0x130>
  memset(&de, 0, sizeof(de));
    80005c0e:	4641                	li	a2,16
    80005c10:	4581                	li	a1,0
    80005c12:	fc040513          	addi	a0,s0,-64
    80005c16:	ffffb097          	auipc	ra,0xffffb
    80005c1a:	0bc080e7          	jalr	188(ra) # 80000cd2 <memset>
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80005c1e:	4741                	li	a4,16
    80005c20:	f2c42683          	lw	a3,-212(s0)
    80005c24:	fc040613          	addi	a2,s0,-64
    80005c28:	4581                	li	a1,0
    80005c2a:	8526                	mv	a0,s1
    80005c2c:	ffffe097          	auipc	ra,0xffffe
    80005c30:	50c080e7          	jalr	1292(ra) # 80004138 <writei>
    80005c34:	47c1                	li	a5,16
    80005c36:	0af51563          	bne	a0,a5,80005ce0 <sys_unlink+0x17c>
  if(ip->type == T_DIR){
    80005c3a:	04491703          	lh	a4,68(s2)
    80005c3e:	4785                	li	a5,1
    80005c40:	0af70863          	beq	a4,a5,80005cf0 <sys_unlink+0x18c>
  iunlockput(dp);
    80005c44:	8526                	mv	a0,s1
    80005c46:	ffffe097          	auipc	ra,0xffffe
    80005c4a:	3a8080e7          	jalr	936(ra) # 80003fee <iunlockput>
  ip->nlink--;
    80005c4e:	04a95783          	lhu	a5,74(s2)
    80005c52:	37fd                	addiw	a5,a5,-1
    80005c54:	04f91523          	sh	a5,74(s2)
  iupdate(ip);
    80005c58:	854a                	mv	a0,s2
    80005c5a:	ffffe097          	auipc	ra,0xffffe
    80005c5e:	066080e7          	jalr	102(ra) # 80003cc0 <iupdate>
  iunlockput(ip);
    80005c62:	854a                	mv	a0,s2
    80005c64:	ffffe097          	auipc	ra,0xffffe
    80005c68:	38a080e7          	jalr	906(ra) # 80003fee <iunlockput>
  end_op();
    80005c6c:	fffff097          	auipc	ra,0xfffff
    80005c70:	b6a080e7          	jalr	-1174(ra) # 800047d6 <end_op>
  return 0;
    80005c74:	4501                	li	a0,0
    80005c76:	a84d                	j	80005d28 <sys_unlink+0x1c4>
    end_op();
    80005c78:	fffff097          	auipc	ra,0xfffff
    80005c7c:	b5e080e7          	jalr	-1186(ra) # 800047d6 <end_op>
    return -1;
    80005c80:	557d                	li	a0,-1
    80005c82:	a05d                	j	80005d28 <sys_unlink+0x1c4>
    panic("unlink: nlink < 1");
    80005c84:	00003517          	auipc	a0,0x3
    80005c88:	a9c50513          	addi	a0,a0,-1380 # 80008720 <syscalls+0x2d0>
    80005c8c:	ffffb097          	auipc	ra,0xffffb
    80005c90:	8b4080e7          	jalr	-1868(ra) # 80000540 <panic>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    80005c94:	04c92703          	lw	a4,76(s2)
    80005c98:	02000793          	li	a5,32
    80005c9c:	f6e7f9e3          	bgeu	a5,a4,80005c0e <sys_unlink+0xaa>
    80005ca0:	02000993          	li	s3,32
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80005ca4:	4741                	li	a4,16
    80005ca6:	86ce                	mv	a3,s3
    80005ca8:	f1840613          	addi	a2,s0,-232
    80005cac:	4581                	li	a1,0
    80005cae:	854a                	mv	a0,s2
    80005cb0:	ffffe097          	auipc	ra,0xffffe
    80005cb4:	390080e7          	jalr	912(ra) # 80004040 <readi>
    80005cb8:	47c1                	li	a5,16
    80005cba:	00f51b63          	bne	a0,a5,80005cd0 <sys_unlink+0x16c>
    if(de.inum != 0)
    80005cbe:	f1845783          	lhu	a5,-232(s0)
    80005cc2:	e7a1                	bnez	a5,80005d0a <sys_unlink+0x1a6>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    80005cc4:	29c1                	addiw	s3,s3,16
    80005cc6:	04c92783          	lw	a5,76(s2)
    80005cca:	fcf9ede3          	bltu	s3,a5,80005ca4 <sys_unlink+0x140>
    80005cce:	b781                	j	80005c0e <sys_unlink+0xaa>
      panic("isdirempty: readi");
    80005cd0:	00003517          	auipc	a0,0x3
    80005cd4:	a6850513          	addi	a0,a0,-1432 # 80008738 <syscalls+0x2e8>
    80005cd8:	ffffb097          	auipc	ra,0xffffb
    80005cdc:	868080e7          	jalr	-1944(ra) # 80000540 <panic>
    panic("unlink: writei");
    80005ce0:	00003517          	auipc	a0,0x3
    80005ce4:	a7050513          	addi	a0,a0,-1424 # 80008750 <syscalls+0x300>
    80005ce8:	ffffb097          	auipc	ra,0xffffb
    80005cec:	858080e7          	jalr	-1960(ra) # 80000540 <panic>
    dp->nlink--;
    80005cf0:	04a4d783          	lhu	a5,74(s1)
    80005cf4:	37fd                	addiw	a5,a5,-1
    80005cf6:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    80005cfa:	8526                	mv	a0,s1
    80005cfc:	ffffe097          	auipc	ra,0xffffe
    80005d00:	fc4080e7          	jalr	-60(ra) # 80003cc0 <iupdate>
    80005d04:	b781                	j	80005c44 <sys_unlink+0xe0>
    return -1;
    80005d06:	557d                	li	a0,-1
    80005d08:	a005                	j	80005d28 <sys_unlink+0x1c4>
    iunlockput(ip);
    80005d0a:	854a                	mv	a0,s2
    80005d0c:	ffffe097          	auipc	ra,0xffffe
    80005d10:	2e2080e7          	jalr	738(ra) # 80003fee <iunlockput>
  iunlockput(dp);
    80005d14:	8526                	mv	a0,s1
    80005d16:	ffffe097          	auipc	ra,0xffffe
    80005d1a:	2d8080e7          	jalr	728(ra) # 80003fee <iunlockput>
  end_op();
    80005d1e:	fffff097          	auipc	ra,0xfffff
    80005d22:	ab8080e7          	jalr	-1352(ra) # 800047d6 <end_op>
  return -1;
    80005d26:	557d                	li	a0,-1
}
    80005d28:	70ae                	ld	ra,232(sp)
    80005d2a:	740e                	ld	s0,224(sp)
    80005d2c:	64ee                	ld	s1,216(sp)
    80005d2e:	694e                	ld	s2,208(sp)
    80005d30:	69ae                	ld	s3,200(sp)
    80005d32:	616d                	addi	sp,sp,240
    80005d34:	8082                	ret

0000000080005d36 <sys_open>:

uint64
sys_open(void)
{
    80005d36:	7131                	addi	sp,sp,-192
    80005d38:	fd06                	sd	ra,184(sp)
    80005d3a:	f922                	sd	s0,176(sp)
    80005d3c:	f526                	sd	s1,168(sp)
    80005d3e:	f14a                	sd	s2,160(sp)
    80005d40:	ed4e                	sd	s3,152(sp)
    80005d42:	0180                	addi	s0,sp,192
  int fd, omode;
  struct file *f;
  struct inode *ip;
  int n;

  argint(1, &omode);
    80005d44:	f4c40593          	addi	a1,s0,-180
    80005d48:	4505                	li	a0,1
    80005d4a:	ffffd097          	auipc	ra,0xffffd
    80005d4e:	34c080e7          	jalr	844(ra) # 80003096 <argint>
  if((n = argstr(0, path, MAXPATH)) < 0)
    80005d52:	08000613          	li	a2,128
    80005d56:	f5040593          	addi	a1,s0,-176
    80005d5a:	4501                	li	a0,0
    80005d5c:	ffffd097          	auipc	ra,0xffffd
    80005d60:	37a080e7          	jalr	890(ra) # 800030d6 <argstr>
    80005d64:	87aa                	mv	a5,a0
    return -1;
    80005d66:	557d                	li	a0,-1
  if((n = argstr(0, path, MAXPATH)) < 0)
    80005d68:	0a07c963          	bltz	a5,80005e1a <sys_open+0xe4>

  begin_op();
    80005d6c:	fffff097          	auipc	ra,0xfffff
    80005d70:	9ec080e7          	jalr	-1556(ra) # 80004758 <begin_op>

  if(omode & O_CREATE){
    80005d74:	f4c42783          	lw	a5,-180(s0)
    80005d78:	2007f793          	andi	a5,a5,512
    80005d7c:	cfc5                	beqz	a5,80005e34 <sys_open+0xfe>
    ip = create(path, T_FILE, 0, 0);
    80005d7e:	4681                	li	a3,0
    80005d80:	4601                	li	a2,0
    80005d82:	4589                	li	a1,2
    80005d84:	f5040513          	addi	a0,s0,-176
    80005d88:	00000097          	auipc	ra,0x0
    80005d8c:	972080e7          	jalr	-1678(ra) # 800056fa <create>
    80005d90:	84aa                	mv	s1,a0
    if(ip == 0){
    80005d92:	c959                	beqz	a0,80005e28 <sys_open+0xf2>
      end_op();
      return -1;
    }
  }

  if(ip->type == T_DEVICE && (ip->major < 0 || ip->major >= NDEV)){
    80005d94:	04449703          	lh	a4,68(s1)
    80005d98:	478d                	li	a5,3
    80005d9a:	00f71763          	bne	a4,a5,80005da8 <sys_open+0x72>
    80005d9e:	0464d703          	lhu	a4,70(s1)
    80005da2:	47a5                	li	a5,9
    80005da4:	0ce7ed63          	bltu	a5,a4,80005e7e <sys_open+0x148>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if((f = filealloc()) == 0 || (fd = fdalloc(f)) < 0){
    80005da8:	fffff097          	auipc	ra,0xfffff
    80005dac:	dbc080e7          	jalr	-580(ra) # 80004b64 <filealloc>
    80005db0:	89aa                	mv	s3,a0
    80005db2:	10050363          	beqz	a0,80005eb8 <sys_open+0x182>
    80005db6:	00000097          	auipc	ra,0x0
    80005dba:	902080e7          	jalr	-1790(ra) # 800056b8 <fdalloc>
    80005dbe:	892a                	mv	s2,a0
    80005dc0:	0e054763          	bltz	a0,80005eae <sys_open+0x178>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if(ip->type == T_DEVICE){
    80005dc4:	04449703          	lh	a4,68(s1)
    80005dc8:	478d                	li	a5,3
    80005dca:	0cf70563          	beq	a4,a5,80005e94 <sys_open+0x15e>
    f->type = FD_DEVICE;
    f->major = ip->major;
  } else {
    f->type = FD_INODE;
    80005dce:	4789                	li	a5,2
    80005dd0:	00f9a023          	sw	a5,0(s3)
    f->off = 0;
    80005dd4:	0209a023          	sw	zero,32(s3)
  }
  f->ip = ip;
    80005dd8:	0099bc23          	sd	s1,24(s3)
  f->readable = !(omode & O_WRONLY);
    80005ddc:	f4c42783          	lw	a5,-180(s0)
    80005de0:	0017c713          	xori	a4,a5,1
    80005de4:	8b05                	andi	a4,a4,1
    80005de6:	00e98423          	sb	a4,8(s3)
  f->writable = (omode & O_WRONLY) || (omode & O_RDWR);
    80005dea:	0037f713          	andi	a4,a5,3
    80005dee:	00e03733          	snez	a4,a4
    80005df2:	00e984a3          	sb	a4,9(s3)

  if((omode & O_TRUNC) && ip->type == T_FILE){
    80005df6:	4007f793          	andi	a5,a5,1024
    80005dfa:	c791                	beqz	a5,80005e06 <sys_open+0xd0>
    80005dfc:	04449703          	lh	a4,68(s1)
    80005e00:	4789                	li	a5,2
    80005e02:	0af70063          	beq	a4,a5,80005ea2 <sys_open+0x16c>
    itrunc(ip);
  }

  iunlock(ip);
    80005e06:	8526                	mv	a0,s1
    80005e08:	ffffe097          	auipc	ra,0xffffe
    80005e0c:	046080e7          	jalr	70(ra) # 80003e4e <iunlock>
  end_op();
    80005e10:	fffff097          	auipc	ra,0xfffff
    80005e14:	9c6080e7          	jalr	-1594(ra) # 800047d6 <end_op>

  return fd;
    80005e18:	854a                	mv	a0,s2
}
    80005e1a:	70ea                	ld	ra,184(sp)
    80005e1c:	744a                	ld	s0,176(sp)
    80005e1e:	74aa                	ld	s1,168(sp)
    80005e20:	790a                	ld	s2,160(sp)
    80005e22:	69ea                	ld	s3,152(sp)
    80005e24:	6129                	addi	sp,sp,192
    80005e26:	8082                	ret
      end_op();
    80005e28:	fffff097          	auipc	ra,0xfffff
    80005e2c:	9ae080e7          	jalr	-1618(ra) # 800047d6 <end_op>
      return -1;
    80005e30:	557d                	li	a0,-1
    80005e32:	b7e5                	j	80005e1a <sys_open+0xe4>
    if((ip = namei(path)) == 0){
    80005e34:	f5040513          	addi	a0,s0,-176
    80005e38:	ffffe097          	auipc	ra,0xffffe
    80005e3c:	700080e7          	jalr	1792(ra) # 80004538 <namei>
    80005e40:	84aa                	mv	s1,a0
    80005e42:	c905                	beqz	a0,80005e72 <sys_open+0x13c>
    ilock(ip);
    80005e44:	ffffe097          	auipc	ra,0xffffe
    80005e48:	f48080e7          	jalr	-184(ra) # 80003d8c <ilock>
    if(ip->type == T_DIR && omode != O_RDONLY){
    80005e4c:	04449703          	lh	a4,68(s1)
    80005e50:	4785                	li	a5,1
    80005e52:	f4f711e3          	bne	a4,a5,80005d94 <sys_open+0x5e>
    80005e56:	f4c42783          	lw	a5,-180(s0)
    80005e5a:	d7b9                	beqz	a5,80005da8 <sys_open+0x72>
      iunlockput(ip);
    80005e5c:	8526                	mv	a0,s1
    80005e5e:	ffffe097          	auipc	ra,0xffffe
    80005e62:	190080e7          	jalr	400(ra) # 80003fee <iunlockput>
      end_op();
    80005e66:	fffff097          	auipc	ra,0xfffff
    80005e6a:	970080e7          	jalr	-1680(ra) # 800047d6 <end_op>
      return -1;
    80005e6e:	557d                	li	a0,-1
    80005e70:	b76d                	j	80005e1a <sys_open+0xe4>
      end_op();
    80005e72:	fffff097          	auipc	ra,0xfffff
    80005e76:	964080e7          	jalr	-1692(ra) # 800047d6 <end_op>
      return -1;
    80005e7a:	557d                	li	a0,-1
    80005e7c:	bf79                	j	80005e1a <sys_open+0xe4>
    iunlockput(ip);
    80005e7e:	8526                	mv	a0,s1
    80005e80:	ffffe097          	auipc	ra,0xffffe
    80005e84:	16e080e7          	jalr	366(ra) # 80003fee <iunlockput>
    end_op();
    80005e88:	fffff097          	auipc	ra,0xfffff
    80005e8c:	94e080e7          	jalr	-1714(ra) # 800047d6 <end_op>
    return -1;
    80005e90:	557d                	li	a0,-1
    80005e92:	b761                	j	80005e1a <sys_open+0xe4>
    f->type = FD_DEVICE;
    80005e94:	00f9a023          	sw	a5,0(s3)
    f->major = ip->major;
    80005e98:	04649783          	lh	a5,70(s1)
    80005e9c:	02f99223          	sh	a5,36(s3)
    80005ea0:	bf25                	j	80005dd8 <sys_open+0xa2>
    itrunc(ip);
    80005ea2:	8526                	mv	a0,s1
    80005ea4:	ffffe097          	auipc	ra,0xffffe
    80005ea8:	ff6080e7          	jalr	-10(ra) # 80003e9a <itrunc>
    80005eac:	bfa9                	j	80005e06 <sys_open+0xd0>
      fileclose(f);
    80005eae:	854e                	mv	a0,s3
    80005eb0:	fffff097          	auipc	ra,0xfffff
    80005eb4:	d70080e7          	jalr	-656(ra) # 80004c20 <fileclose>
    iunlockput(ip);
    80005eb8:	8526                	mv	a0,s1
    80005eba:	ffffe097          	auipc	ra,0xffffe
    80005ebe:	134080e7          	jalr	308(ra) # 80003fee <iunlockput>
    end_op();
    80005ec2:	fffff097          	auipc	ra,0xfffff
    80005ec6:	914080e7          	jalr	-1772(ra) # 800047d6 <end_op>
    return -1;
    80005eca:	557d                	li	a0,-1
    80005ecc:	b7b9                	j	80005e1a <sys_open+0xe4>

0000000080005ece <sys_mkdir>:

uint64
sys_mkdir(void)
{
    80005ece:	7175                	addi	sp,sp,-144
    80005ed0:	e506                	sd	ra,136(sp)
    80005ed2:	e122                	sd	s0,128(sp)
    80005ed4:	0900                	addi	s0,sp,144
  char path[MAXPATH];
  struct inode *ip;

  begin_op();
    80005ed6:	fffff097          	auipc	ra,0xfffff
    80005eda:	882080e7          	jalr	-1918(ra) # 80004758 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = create(path, T_DIR, 0, 0)) == 0){
    80005ede:	08000613          	li	a2,128
    80005ee2:	f7040593          	addi	a1,s0,-144
    80005ee6:	4501                	li	a0,0
    80005ee8:	ffffd097          	auipc	ra,0xffffd
    80005eec:	1ee080e7          	jalr	494(ra) # 800030d6 <argstr>
    80005ef0:	02054963          	bltz	a0,80005f22 <sys_mkdir+0x54>
    80005ef4:	4681                	li	a3,0
    80005ef6:	4601                	li	a2,0
    80005ef8:	4585                	li	a1,1
    80005efa:	f7040513          	addi	a0,s0,-144
    80005efe:	fffff097          	auipc	ra,0xfffff
    80005f02:	7fc080e7          	jalr	2044(ra) # 800056fa <create>
    80005f06:	cd11                	beqz	a0,80005f22 <sys_mkdir+0x54>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80005f08:	ffffe097          	auipc	ra,0xffffe
    80005f0c:	0e6080e7          	jalr	230(ra) # 80003fee <iunlockput>
  end_op();
    80005f10:	fffff097          	auipc	ra,0xfffff
    80005f14:	8c6080e7          	jalr	-1850(ra) # 800047d6 <end_op>
  return 0;
    80005f18:	4501                	li	a0,0
}
    80005f1a:	60aa                	ld	ra,136(sp)
    80005f1c:	640a                	ld	s0,128(sp)
    80005f1e:	6149                	addi	sp,sp,144
    80005f20:	8082                	ret
    end_op();
    80005f22:	fffff097          	auipc	ra,0xfffff
    80005f26:	8b4080e7          	jalr	-1868(ra) # 800047d6 <end_op>
    return -1;
    80005f2a:	557d                	li	a0,-1
    80005f2c:	b7fd                	j	80005f1a <sys_mkdir+0x4c>

0000000080005f2e <sys_mknod>:

uint64
sys_mknod(void)
{
    80005f2e:	7135                	addi	sp,sp,-160
    80005f30:	ed06                	sd	ra,152(sp)
    80005f32:	e922                	sd	s0,144(sp)
    80005f34:	1100                	addi	s0,sp,160
  struct inode *ip;
  char path[MAXPATH];
  int major, minor;

  begin_op();
    80005f36:	fffff097          	auipc	ra,0xfffff
    80005f3a:	822080e7          	jalr	-2014(ra) # 80004758 <begin_op>
  argint(1, &major);
    80005f3e:	f6c40593          	addi	a1,s0,-148
    80005f42:	4505                	li	a0,1
    80005f44:	ffffd097          	auipc	ra,0xffffd
    80005f48:	152080e7          	jalr	338(ra) # 80003096 <argint>
  argint(2, &minor);
    80005f4c:	f6840593          	addi	a1,s0,-152
    80005f50:	4509                	li	a0,2
    80005f52:	ffffd097          	auipc	ra,0xffffd
    80005f56:	144080e7          	jalr	324(ra) # 80003096 <argint>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80005f5a:	08000613          	li	a2,128
    80005f5e:	f7040593          	addi	a1,s0,-144
    80005f62:	4501                	li	a0,0
    80005f64:	ffffd097          	auipc	ra,0xffffd
    80005f68:	172080e7          	jalr	370(ra) # 800030d6 <argstr>
    80005f6c:	02054b63          	bltz	a0,80005fa2 <sys_mknod+0x74>
     (ip = create(path, T_DEVICE, major, minor)) == 0){
    80005f70:	f6841683          	lh	a3,-152(s0)
    80005f74:	f6c41603          	lh	a2,-148(s0)
    80005f78:	458d                	li	a1,3
    80005f7a:	f7040513          	addi	a0,s0,-144
    80005f7e:	fffff097          	auipc	ra,0xfffff
    80005f82:	77c080e7          	jalr	1916(ra) # 800056fa <create>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80005f86:	cd11                	beqz	a0,80005fa2 <sys_mknod+0x74>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80005f88:	ffffe097          	auipc	ra,0xffffe
    80005f8c:	066080e7          	jalr	102(ra) # 80003fee <iunlockput>
  end_op();
    80005f90:	fffff097          	auipc	ra,0xfffff
    80005f94:	846080e7          	jalr	-1978(ra) # 800047d6 <end_op>
  return 0;
    80005f98:	4501                	li	a0,0
}
    80005f9a:	60ea                	ld	ra,152(sp)
    80005f9c:	644a                	ld	s0,144(sp)
    80005f9e:	610d                	addi	sp,sp,160
    80005fa0:	8082                	ret
    end_op();
    80005fa2:	fffff097          	auipc	ra,0xfffff
    80005fa6:	834080e7          	jalr	-1996(ra) # 800047d6 <end_op>
    return -1;
    80005faa:	557d                	li	a0,-1
    80005fac:	b7fd                	j	80005f9a <sys_mknod+0x6c>

0000000080005fae <sys_chdir>:

uint64
sys_chdir(void)
{
    80005fae:	7135                	addi	sp,sp,-160
    80005fb0:	ed06                	sd	ra,152(sp)
    80005fb2:	e922                	sd	s0,144(sp)
    80005fb4:	e526                	sd	s1,136(sp)
    80005fb6:	e14a                	sd	s2,128(sp)
    80005fb8:	1100                	addi	s0,sp,160
  char path[MAXPATH];
  struct inode *ip;
  struct proc *p = myproc();
    80005fba:	ffffc097          	auipc	ra,0xffffc
    80005fbe:	9f2080e7          	jalr	-1550(ra) # 800019ac <myproc>
    80005fc2:	892a                	mv	s2,a0
  
  begin_op();
    80005fc4:	ffffe097          	auipc	ra,0xffffe
    80005fc8:	794080e7          	jalr	1940(ra) # 80004758 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = namei(path)) == 0){
    80005fcc:	08000613          	li	a2,128
    80005fd0:	f6040593          	addi	a1,s0,-160
    80005fd4:	4501                	li	a0,0
    80005fd6:	ffffd097          	auipc	ra,0xffffd
    80005fda:	100080e7          	jalr	256(ra) # 800030d6 <argstr>
    80005fde:	04054b63          	bltz	a0,80006034 <sys_chdir+0x86>
    80005fe2:	f6040513          	addi	a0,s0,-160
    80005fe6:	ffffe097          	auipc	ra,0xffffe
    80005fea:	552080e7          	jalr	1362(ra) # 80004538 <namei>
    80005fee:	84aa                	mv	s1,a0
    80005ff0:	c131                	beqz	a0,80006034 <sys_chdir+0x86>
    end_op();
    return -1;
  }
  ilock(ip);
    80005ff2:	ffffe097          	auipc	ra,0xffffe
    80005ff6:	d9a080e7          	jalr	-614(ra) # 80003d8c <ilock>
  if(ip->type != T_DIR){
    80005ffa:	04449703          	lh	a4,68(s1)
    80005ffe:	4785                	li	a5,1
    80006000:	04f71063          	bne	a4,a5,80006040 <sys_chdir+0x92>
    iunlockput(ip);
    end_op();
    return -1;
  }
  iunlock(ip);
    80006004:	8526                	mv	a0,s1
    80006006:	ffffe097          	auipc	ra,0xffffe
    8000600a:	e48080e7          	jalr	-440(ra) # 80003e4e <iunlock>
  iput(p->cwd);
    8000600e:	17093503          	ld	a0,368(s2)
    80006012:	ffffe097          	auipc	ra,0xffffe
    80006016:	f34080e7          	jalr	-204(ra) # 80003f46 <iput>
  end_op();
    8000601a:	ffffe097          	auipc	ra,0xffffe
    8000601e:	7bc080e7          	jalr	1980(ra) # 800047d6 <end_op>
  p->cwd = ip;
    80006022:	16993823          	sd	s1,368(s2)
  return 0;
    80006026:	4501                	li	a0,0
}
    80006028:	60ea                	ld	ra,152(sp)
    8000602a:	644a                	ld	s0,144(sp)
    8000602c:	64aa                	ld	s1,136(sp)
    8000602e:	690a                	ld	s2,128(sp)
    80006030:	610d                	addi	sp,sp,160
    80006032:	8082                	ret
    end_op();
    80006034:	ffffe097          	auipc	ra,0xffffe
    80006038:	7a2080e7          	jalr	1954(ra) # 800047d6 <end_op>
    return -1;
    8000603c:	557d                	li	a0,-1
    8000603e:	b7ed                	j	80006028 <sys_chdir+0x7a>
    iunlockput(ip);
    80006040:	8526                	mv	a0,s1
    80006042:	ffffe097          	auipc	ra,0xffffe
    80006046:	fac080e7          	jalr	-84(ra) # 80003fee <iunlockput>
    end_op();
    8000604a:	ffffe097          	auipc	ra,0xffffe
    8000604e:	78c080e7          	jalr	1932(ra) # 800047d6 <end_op>
    return -1;
    80006052:	557d                	li	a0,-1
    80006054:	bfd1                	j	80006028 <sys_chdir+0x7a>

0000000080006056 <sys_exec>:

uint64
sys_exec(void)
{
    80006056:	7145                	addi	sp,sp,-464
    80006058:	e786                	sd	ra,456(sp)
    8000605a:	e3a2                	sd	s0,448(sp)
    8000605c:	ff26                	sd	s1,440(sp)
    8000605e:	fb4a                	sd	s2,432(sp)
    80006060:	f74e                	sd	s3,424(sp)
    80006062:	f352                	sd	s4,416(sp)
    80006064:	ef56                	sd	s5,408(sp)
    80006066:	0b80                	addi	s0,sp,464
  char path[MAXPATH], *argv[MAXARG];
  int i;
  uint64 uargv, uarg;

  argaddr(1, &uargv);
    80006068:	e3840593          	addi	a1,s0,-456
    8000606c:	4505                	li	a0,1
    8000606e:	ffffd097          	auipc	ra,0xffffd
    80006072:	048080e7          	jalr	72(ra) # 800030b6 <argaddr>
  if(argstr(0, path, MAXPATH) < 0) {
    80006076:	08000613          	li	a2,128
    8000607a:	f4040593          	addi	a1,s0,-192
    8000607e:	4501                	li	a0,0
    80006080:	ffffd097          	auipc	ra,0xffffd
    80006084:	056080e7          	jalr	86(ra) # 800030d6 <argstr>
    80006088:	87aa                	mv	a5,a0
    return -1;
    8000608a:	557d                	li	a0,-1
  if(argstr(0, path, MAXPATH) < 0) {
    8000608c:	0c07c363          	bltz	a5,80006152 <sys_exec+0xfc>
  }
  memset(argv, 0, sizeof(argv));
    80006090:	10000613          	li	a2,256
    80006094:	4581                	li	a1,0
    80006096:	e4040513          	addi	a0,s0,-448
    8000609a:	ffffb097          	auipc	ra,0xffffb
    8000609e:	c38080e7          	jalr	-968(ra) # 80000cd2 <memset>
  for(i=0;; i++){
    if(i >= NELEM(argv)){
    800060a2:	e4040493          	addi	s1,s0,-448
  memset(argv, 0, sizeof(argv));
    800060a6:	89a6                	mv	s3,s1
    800060a8:	4901                	li	s2,0
    if(i >= NELEM(argv)){
    800060aa:	02000a13          	li	s4,32
    800060ae:	00090a9b          	sext.w	s5,s2
      goto bad;
    }
    if(fetchaddr(uargv+sizeof(uint64)*i, (uint64*)&uarg) < 0){
    800060b2:	00391513          	slli	a0,s2,0x3
    800060b6:	e3040593          	addi	a1,s0,-464
    800060ba:	e3843783          	ld	a5,-456(s0)
    800060be:	953e                	add	a0,a0,a5
    800060c0:	ffffd097          	auipc	ra,0xffffd
    800060c4:	f38080e7          	jalr	-200(ra) # 80002ff8 <fetchaddr>
    800060c8:	02054a63          	bltz	a0,800060fc <sys_exec+0xa6>
      goto bad;
    }
    if(uarg == 0){
    800060cc:	e3043783          	ld	a5,-464(s0)
    800060d0:	c3b9                	beqz	a5,80006116 <sys_exec+0xc0>
      argv[i] = 0;
      break;
    }
    argv[i] = kalloc();
    800060d2:	ffffb097          	auipc	ra,0xffffb
    800060d6:	a14080e7          	jalr	-1516(ra) # 80000ae6 <kalloc>
    800060da:	85aa                	mv	a1,a0
    800060dc:	00a9b023          	sd	a0,0(s3)
    if(argv[i] == 0)
    800060e0:	cd11                	beqz	a0,800060fc <sys_exec+0xa6>
      goto bad;
    if(fetchstr(uarg, argv[i], PGSIZE) < 0)
    800060e2:	6605                	lui	a2,0x1
    800060e4:	e3043503          	ld	a0,-464(s0)
    800060e8:	ffffd097          	auipc	ra,0xffffd
    800060ec:	f62080e7          	jalr	-158(ra) # 8000304a <fetchstr>
    800060f0:	00054663          	bltz	a0,800060fc <sys_exec+0xa6>
    if(i >= NELEM(argv)){
    800060f4:	0905                	addi	s2,s2,1
    800060f6:	09a1                	addi	s3,s3,8
    800060f8:	fb491be3          	bne	s2,s4,800060ae <sys_exec+0x58>
    kfree(argv[i]);

  return ret;

 bad:
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    800060fc:	f4040913          	addi	s2,s0,-192
    80006100:	6088                	ld	a0,0(s1)
    80006102:	c539                	beqz	a0,80006150 <sys_exec+0xfa>
    kfree(argv[i]);
    80006104:	ffffb097          	auipc	ra,0xffffb
    80006108:	8e4080e7          	jalr	-1820(ra) # 800009e8 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    8000610c:	04a1                	addi	s1,s1,8
    8000610e:	ff2499e3          	bne	s1,s2,80006100 <sys_exec+0xaa>
  return -1;
    80006112:	557d                	li	a0,-1
    80006114:	a83d                	j	80006152 <sys_exec+0xfc>
      argv[i] = 0;
    80006116:	0a8e                	slli	s5,s5,0x3
    80006118:	fc0a8793          	addi	a5,s5,-64
    8000611c:	00878ab3          	add	s5,a5,s0
    80006120:	e80ab023          	sd	zero,-384(s5)
  int ret = exec(path, argv);
    80006124:	e4040593          	addi	a1,s0,-448
    80006128:	f4040513          	addi	a0,s0,-192
    8000612c:	fffff097          	auipc	ra,0xfffff
    80006130:	16e080e7          	jalr	366(ra) # 8000529a <exec>
    80006134:	892a                	mv	s2,a0
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80006136:	f4040993          	addi	s3,s0,-192
    8000613a:	6088                	ld	a0,0(s1)
    8000613c:	c901                	beqz	a0,8000614c <sys_exec+0xf6>
    kfree(argv[i]);
    8000613e:	ffffb097          	auipc	ra,0xffffb
    80006142:	8aa080e7          	jalr	-1878(ra) # 800009e8 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80006146:	04a1                	addi	s1,s1,8
    80006148:	ff3499e3          	bne	s1,s3,8000613a <sys_exec+0xe4>
  return ret;
    8000614c:	854a                	mv	a0,s2
    8000614e:	a011                	j	80006152 <sys_exec+0xfc>
  return -1;
    80006150:	557d                	li	a0,-1
}
    80006152:	60be                	ld	ra,456(sp)
    80006154:	641e                	ld	s0,448(sp)
    80006156:	74fa                	ld	s1,440(sp)
    80006158:	795a                	ld	s2,432(sp)
    8000615a:	79ba                	ld	s3,424(sp)
    8000615c:	7a1a                	ld	s4,416(sp)
    8000615e:	6afa                	ld	s5,408(sp)
    80006160:	6179                	addi	sp,sp,464
    80006162:	8082                	ret

0000000080006164 <sys_pipe>:

uint64
sys_pipe(void)
{
    80006164:	7139                	addi	sp,sp,-64
    80006166:	fc06                	sd	ra,56(sp)
    80006168:	f822                	sd	s0,48(sp)
    8000616a:	f426                	sd	s1,40(sp)
    8000616c:	0080                	addi	s0,sp,64
  uint64 fdarray; // user pointer to array of two integers
  struct file *rf, *wf;
  int fd0, fd1;
  struct proc *p = myproc();
    8000616e:	ffffc097          	auipc	ra,0xffffc
    80006172:	83e080e7          	jalr	-1986(ra) # 800019ac <myproc>
    80006176:	84aa                	mv	s1,a0

  argaddr(0, &fdarray);
    80006178:	fd840593          	addi	a1,s0,-40
    8000617c:	4501                	li	a0,0
    8000617e:	ffffd097          	auipc	ra,0xffffd
    80006182:	f38080e7          	jalr	-200(ra) # 800030b6 <argaddr>
  if(pipealloc(&rf, &wf) < 0)
    80006186:	fc840593          	addi	a1,s0,-56
    8000618a:	fd040513          	addi	a0,s0,-48
    8000618e:	fffff097          	auipc	ra,0xfffff
    80006192:	dc2080e7          	jalr	-574(ra) # 80004f50 <pipealloc>
    return -1;
    80006196:	57fd                	li	a5,-1
  if(pipealloc(&rf, &wf) < 0)
    80006198:	0c054463          	bltz	a0,80006260 <sys_pipe+0xfc>
  fd0 = -1;
    8000619c:	fcf42223          	sw	a5,-60(s0)
  if((fd0 = fdalloc(rf)) < 0 || (fd1 = fdalloc(wf)) < 0){
    800061a0:	fd043503          	ld	a0,-48(s0)
    800061a4:	fffff097          	auipc	ra,0xfffff
    800061a8:	514080e7          	jalr	1300(ra) # 800056b8 <fdalloc>
    800061ac:	fca42223          	sw	a0,-60(s0)
    800061b0:	08054b63          	bltz	a0,80006246 <sys_pipe+0xe2>
    800061b4:	fc843503          	ld	a0,-56(s0)
    800061b8:	fffff097          	auipc	ra,0xfffff
    800061bc:	500080e7          	jalr	1280(ra) # 800056b8 <fdalloc>
    800061c0:	fca42023          	sw	a0,-64(s0)
    800061c4:	06054863          	bltz	a0,80006234 <sys_pipe+0xd0>
      p->ofile[fd0] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    800061c8:	4691                	li	a3,4
    800061ca:	fc440613          	addi	a2,s0,-60
    800061ce:	fd843583          	ld	a1,-40(s0)
    800061d2:	78a8                	ld	a0,112(s1)
    800061d4:	ffffb097          	auipc	ra,0xffffb
    800061d8:	498080e7          	jalr	1176(ra) # 8000166c <copyout>
    800061dc:	02054063          	bltz	a0,800061fc <sys_pipe+0x98>
     copyout(p->pagetable, fdarray+sizeof(fd0), (char *)&fd1, sizeof(fd1)) < 0){
    800061e0:	4691                	li	a3,4
    800061e2:	fc040613          	addi	a2,s0,-64
    800061e6:	fd843583          	ld	a1,-40(s0)
    800061ea:	0591                	addi	a1,a1,4
    800061ec:	78a8                	ld	a0,112(s1)
    800061ee:	ffffb097          	auipc	ra,0xffffb
    800061f2:	47e080e7          	jalr	1150(ra) # 8000166c <copyout>
    p->ofile[fd1] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  return 0;
    800061f6:	4781                	li	a5,0
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    800061f8:	06055463          	bgez	a0,80006260 <sys_pipe+0xfc>
    p->ofile[fd0] = 0;
    800061fc:	fc442783          	lw	a5,-60(s0)
    80006200:	07f9                	addi	a5,a5,30
    80006202:	078e                	slli	a5,a5,0x3
    80006204:	97a6                	add	a5,a5,s1
    80006206:	0007b023          	sd	zero,0(a5)
    p->ofile[fd1] = 0;
    8000620a:	fc042783          	lw	a5,-64(s0)
    8000620e:	07f9                	addi	a5,a5,30
    80006210:	078e                	slli	a5,a5,0x3
    80006212:	94be                	add	s1,s1,a5
    80006214:	0004b023          	sd	zero,0(s1)
    fileclose(rf);
    80006218:	fd043503          	ld	a0,-48(s0)
    8000621c:	fffff097          	auipc	ra,0xfffff
    80006220:	a04080e7          	jalr	-1532(ra) # 80004c20 <fileclose>
    fileclose(wf);
    80006224:	fc843503          	ld	a0,-56(s0)
    80006228:	fffff097          	auipc	ra,0xfffff
    8000622c:	9f8080e7          	jalr	-1544(ra) # 80004c20 <fileclose>
    return -1;
    80006230:	57fd                	li	a5,-1
    80006232:	a03d                	j	80006260 <sys_pipe+0xfc>
    if(fd0 >= 0)
    80006234:	fc442783          	lw	a5,-60(s0)
    80006238:	0007c763          	bltz	a5,80006246 <sys_pipe+0xe2>
      p->ofile[fd0] = 0;
    8000623c:	07f9                	addi	a5,a5,30
    8000623e:	078e                	slli	a5,a5,0x3
    80006240:	97a6                	add	a5,a5,s1
    80006242:	0007b023          	sd	zero,0(a5)
    fileclose(rf);
    80006246:	fd043503          	ld	a0,-48(s0)
    8000624a:	fffff097          	auipc	ra,0xfffff
    8000624e:	9d6080e7          	jalr	-1578(ra) # 80004c20 <fileclose>
    fileclose(wf);
    80006252:	fc843503          	ld	a0,-56(s0)
    80006256:	fffff097          	auipc	ra,0xfffff
    8000625a:	9ca080e7          	jalr	-1590(ra) # 80004c20 <fileclose>
    return -1;
    8000625e:	57fd                	li	a5,-1
}
    80006260:	853e                	mv	a0,a5
    80006262:	70e2                	ld	ra,56(sp)
    80006264:	7442                	ld	s0,48(sp)
    80006266:	74a2                	ld	s1,40(sp)
    80006268:	6121                	addi	sp,sp,64
    8000626a:	8082                	ret
    8000626c:	0000                	unimp
	...

0000000080006270 <kernelvec>:
    80006270:	7111                	addi	sp,sp,-256
    80006272:	e006                	sd	ra,0(sp)
    80006274:	e40a                	sd	sp,8(sp)
    80006276:	e80e                	sd	gp,16(sp)
    80006278:	ec12                	sd	tp,24(sp)
    8000627a:	f016                	sd	t0,32(sp)
    8000627c:	f41a                	sd	t1,40(sp)
    8000627e:	f81e                	sd	t2,48(sp)
    80006280:	fc22                	sd	s0,56(sp)
    80006282:	e0a6                	sd	s1,64(sp)
    80006284:	e4aa                	sd	a0,72(sp)
    80006286:	e8ae                	sd	a1,80(sp)
    80006288:	ecb2                	sd	a2,88(sp)
    8000628a:	f0b6                	sd	a3,96(sp)
    8000628c:	f4ba                	sd	a4,104(sp)
    8000628e:	f8be                	sd	a5,112(sp)
    80006290:	fcc2                	sd	a6,120(sp)
    80006292:	e146                	sd	a7,128(sp)
    80006294:	e54a                	sd	s2,136(sp)
    80006296:	e94e                	sd	s3,144(sp)
    80006298:	ed52                	sd	s4,152(sp)
    8000629a:	f156                	sd	s5,160(sp)
    8000629c:	f55a                	sd	s6,168(sp)
    8000629e:	f95e                	sd	s7,176(sp)
    800062a0:	fd62                	sd	s8,184(sp)
    800062a2:	e1e6                	sd	s9,192(sp)
    800062a4:	e5ea                	sd	s10,200(sp)
    800062a6:	e9ee                	sd	s11,208(sp)
    800062a8:	edf2                	sd	t3,216(sp)
    800062aa:	f1f6                	sd	t4,224(sp)
    800062ac:	f5fa                	sd	t5,232(sp)
    800062ae:	f9fe                	sd	t6,240(sp)
    800062b0:	a9bfc0ef          	jal	ra,80002d4a <kerneltrap>
    800062b4:	6082                	ld	ra,0(sp)
    800062b6:	6122                	ld	sp,8(sp)
    800062b8:	61c2                	ld	gp,16(sp)
    800062ba:	7282                	ld	t0,32(sp)
    800062bc:	7322                	ld	t1,40(sp)
    800062be:	73c2                	ld	t2,48(sp)
    800062c0:	7462                	ld	s0,56(sp)
    800062c2:	6486                	ld	s1,64(sp)
    800062c4:	6526                	ld	a0,72(sp)
    800062c6:	65c6                	ld	a1,80(sp)
    800062c8:	6666                	ld	a2,88(sp)
    800062ca:	7686                	ld	a3,96(sp)
    800062cc:	7726                	ld	a4,104(sp)
    800062ce:	77c6                	ld	a5,112(sp)
    800062d0:	7866                	ld	a6,120(sp)
    800062d2:	688a                	ld	a7,128(sp)
    800062d4:	692a                	ld	s2,136(sp)
    800062d6:	69ca                	ld	s3,144(sp)
    800062d8:	6a6a                	ld	s4,152(sp)
    800062da:	7a8a                	ld	s5,160(sp)
    800062dc:	7b2a                	ld	s6,168(sp)
    800062de:	7bca                	ld	s7,176(sp)
    800062e0:	7c6a                	ld	s8,184(sp)
    800062e2:	6c8e                	ld	s9,192(sp)
    800062e4:	6d2e                	ld	s10,200(sp)
    800062e6:	6dce                	ld	s11,208(sp)
    800062e8:	6e6e                	ld	t3,216(sp)
    800062ea:	7e8e                	ld	t4,224(sp)
    800062ec:	7f2e                	ld	t5,232(sp)
    800062ee:	7fce                	ld	t6,240(sp)
    800062f0:	6111                	addi	sp,sp,256
    800062f2:	10200073          	sret
    800062f6:	00000013          	nop
    800062fa:	00000013          	nop
    800062fe:	0001                	nop

0000000080006300 <timervec>:
    80006300:	34051573          	csrrw	a0,mscratch,a0
    80006304:	e10c                	sd	a1,0(a0)
    80006306:	e510                	sd	a2,8(a0)
    80006308:	e914                	sd	a3,16(a0)
    8000630a:	6d0c                	ld	a1,24(a0)
    8000630c:	7110                	ld	a2,32(a0)
    8000630e:	6194                	ld	a3,0(a1)
    80006310:	96b2                	add	a3,a3,a2
    80006312:	e194                	sd	a3,0(a1)
    80006314:	4589                	li	a1,2
    80006316:	14459073          	csrw	sip,a1
    8000631a:	6914                	ld	a3,16(a0)
    8000631c:	6510                	ld	a2,8(a0)
    8000631e:	610c                	ld	a1,0(a0)
    80006320:	34051573          	csrrw	a0,mscratch,a0
    80006324:	30200073          	mret
	...

000000008000632a <plicinit>:
// the riscv Platform Level Interrupt Controller (PLIC).
//

void
plicinit(void)
{
    8000632a:	1141                	addi	sp,sp,-16
    8000632c:	e422                	sd	s0,8(sp)
    8000632e:	0800                	addi	s0,sp,16
  // set desired IRQ priorities non-zero (otherwise disabled).
  *(uint32*)(PLIC + UART0_IRQ*4) = 1;
    80006330:	0c0007b7          	lui	a5,0xc000
    80006334:	4705                	li	a4,1
    80006336:	d798                	sw	a4,40(a5)
  *(uint32*)(PLIC + VIRTIO0_IRQ*4) = 1;
    80006338:	c3d8                	sw	a4,4(a5)
}
    8000633a:	6422                	ld	s0,8(sp)
    8000633c:	0141                	addi	sp,sp,16
    8000633e:	8082                	ret

0000000080006340 <plicinithart>:

void
plicinithart(void)
{
    80006340:	1141                	addi	sp,sp,-16
    80006342:	e406                	sd	ra,8(sp)
    80006344:	e022                	sd	s0,0(sp)
    80006346:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80006348:	ffffb097          	auipc	ra,0xffffb
    8000634c:	638080e7          	jalr	1592(ra) # 80001980 <cpuid>
  
  // set enable bits for this hart's S-mode
  // for the uart and virtio disk.
  *(uint32*)PLIC_SENABLE(hart) = (1 << UART0_IRQ) | (1 << VIRTIO0_IRQ);
    80006350:	0085171b          	slliw	a4,a0,0x8
    80006354:	0c0027b7          	lui	a5,0xc002
    80006358:	97ba                	add	a5,a5,a4
    8000635a:	40200713          	li	a4,1026
    8000635e:	08e7a023          	sw	a4,128(a5) # c002080 <_entry-0x73ffdf80>

  // set this hart's S-mode priority threshold to 0.
  *(uint32*)PLIC_SPRIORITY(hart) = 0;
    80006362:	00d5151b          	slliw	a0,a0,0xd
    80006366:	0c2017b7          	lui	a5,0xc201
    8000636a:	97aa                	add	a5,a5,a0
    8000636c:	0007a023          	sw	zero,0(a5) # c201000 <_entry-0x73dff000>
}
    80006370:	60a2                	ld	ra,8(sp)
    80006372:	6402                	ld	s0,0(sp)
    80006374:	0141                	addi	sp,sp,16
    80006376:	8082                	ret

0000000080006378 <plic_claim>:

// ask the PLIC what interrupt we should serve.
int
plic_claim(void)
{
    80006378:	1141                	addi	sp,sp,-16
    8000637a:	e406                	sd	ra,8(sp)
    8000637c:	e022                	sd	s0,0(sp)
    8000637e:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80006380:	ffffb097          	auipc	ra,0xffffb
    80006384:	600080e7          	jalr	1536(ra) # 80001980 <cpuid>
  int irq = *(uint32*)PLIC_SCLAIM(hart);
    80006388:	00d5151b          	slliw	a0,a0,0xd
    8000638c:	0c2017b7          	lui	a5,0xc201
    80006390:	97aa                	add	a5,a5,a0
  return irq;
}
    80006392:	43c8                	lw	a0,4(a5)
    80006394:	60a2                	ld	ra,8(sp)
    80006396:	6402                	ld	s0,0(sp)
    80006398:	0141                	addi	sp,sp,16
    8000639a:	8082                	ret

000000008000639c <plic_complete>:

// tell the PLIC we've served this IRQ.
void
plic_complete(int irq)
{
    8000639c:	1101                	addi	sp,sp,-32
    8000639e:	ec06                	sd	ra,24(sp)
    800063a0:	e822                	sd	s0,16(sp)
    800063a2:	e426                	sd	s1,8(sp)
    800063a4:	1000                	addi	s0,sp,32
    800063a6:	84aa                	mv	s1,a0
  int hart = cpuid();
    800063a8:	ffffb097          	auipc	ra,0xffffb
    800063ac:	5d8080e7          	jalr	1496(ra) # 80001980 <cpuid>
  *(uint32*)PLIC_SCLAIM(hart) = irq;
    800063b0:	00d5151b          	slliw	a0,a0,0xd
    800063b4:	0c2017b7          	lui	a5,0xc201
    800063b8:	97aa                	add	a5,a5,a0
    800063ba:	c3c4                	sw	s1,4(a5)
}
    800063bc:	60e2                	ld	ra,24(sp)
    800063be:	6442                	ld	s0,16(sp)
    800063c0:	64a2                	ld	s1,8(sp)
    800063c2:	6105                	addi	sp,sp,32
    800063c4:	8082                	ret

00000000800063c6 <free_desc>:
}

// mark a descriptor as free.
static void
free_desc(int i)
{
    800063c6:	1141                	addi	sp,sp,-16
    800063c8:	e406                	sd	ra,8(sp)
    800063ca:	e022                	sd	s0,0(sp)
    800063cc:	0800                	addi	s0,sp,16
  if(i >= NUM)
    800063ce:	479d                	li	a5,7
    800063d0:	04a7cc63          	blt	a5,a0,80006428 <free_desc+0x62>
    panic("free_desc 1");
  if(disk.free[i])
    800063d4:	0001c797          	auipc	a5,0x1c
    800063d8:	66c78793          	addi	a5,a5,1644 # 80022a40 <disk>
    800063dc:	97aa                	add	a5,a5,a0
    800063de:	0187c783          	lbu	a5,24(a5)
    800063e2:	ebb9                	bnez	a5,80006438 <free_desc+0x72>
    panic("free_desc 2");
  disk.desc[i].addr = 0;
    800063e4:	00451693          	slli	a3,a0,0x4
    800063e8:	0001c797          	auipc	a5,0x1c
    800063ec:	65878793          	addi	a5,a5,1624 # 80022a40 <disk>
    800063f0:	6398                	ld	a4,0(a5)
    800063f2:	9736                	add	a4,a4,a3
    800063f4:	00073023          	sd	zero,0(a4)
  disk.desc[i].len = 0;
    800063f8:	6398                	ld	a4,0(a5)
    800063fa:	9736                	add	a4,a4,a3
    800063fc:	00072423          	sw	zero,8(a4)
  disk.desc[i].flags = 0;
    80006400:	00071623          	sh	zero,12(a4)
  disk.desc[i].next = 0;
    80006404:	00071723          	sh	zero,14(a4)
  disk.free[i] = 1;
    80006408:	97aa                	add	a5,a5,a0
    8000640a:	4705                	li	a4,1
    8000640c:	00e78c23          	sb	a4,24(a5)
  wakeup(&disk.free[0]);
    80006410:	0001c517          	auipc	a0,0x1c
    80006414:	64850513          	addi	a0,a0,1608 # 80022a58 <disk+0x18>
    80006418:	ffffc097          	auipc	ra,0xffffc
    8000641c:	d64080e7          	jalr	-668(ra) # 8000217c <wakeup>
}
    80006420:	60a2                	ld	ra,8(sp)
    80006422:	6402                	ld	s0,0(sp)
    80006424:	0141                	addi	sp,sp,16
    80006426:	8082                	ret
    panic("free_desc 1");
    80006428:	00002517          	auipc	a0,0x2
    8000642c:	33850513          	addi	a0,a0,824 # 80008760 <syscalls+0x310>
    80006430:	ffffa097          	auipc	ra,0xffffa
    80006434:	110080e7          	jalr	272(ra) # 80000540 <panic>
    panic("free_desc 2");
    80006438:	00002517          	auipc	a0,0x2
    8000643c:	33850513          	addi	a0,a0,824 # 80008770 <syscalls+0x320>
    80006440:	ffffa097          	auipc	ra,0xffffa
    80006444:	100080e7          	jalr	256(ra) # 80000540 <panic>

0000000080006448 <virtio_disk_init>:
{
    80006448:	1101                	addi	sp,sp,-32
    8000644a:	ec06                	sd	ra,24(sp)
    8000644c:	e822                	sd	s0,16(sp)
    8000644e:	e426                	sd	s1,8(sp)
    80006450:	e04a                	sd	s2,0(sp)
    80006452:	1000                	addi	s0,sp,32
  initlock(&disk.vdisk_lock, "virtio_disk");
    80006454:	00002597          	auipc	a1,0x2
    80006458:	32c58593          	addi	a1,a1,812 # 80008780 <syscalls+0x330>
    8000645c:	0001c517          	auipc	a0,0x1c
    80006460:	70c50513          	addi	a0,a0,1804 # 80022b68 <disk+0x128>
    80006464:	ffffa097          	auipc	ra,0xffffa
    80006468:	6e2080e7          	jalr	1762(ra) # 80000b46 <initlock>
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    8000646c:	100017b7          	lui	a5,0x10001
    80006470:	4398                	lw	a4,0(a5)
    80006472:	2701                	sext.w	a4,a4
    80006474:	747277b7          	lui	a5,0x74727
    80006478:	97678793          	addi	a5,a5,-1674 # 74726976 <_entry-0xb8d968a>
    8000647c:	14f71b63          	bne	a4,a5,800065d2 <virtio_disk_init+0x18a>
     *R(VIRTIO_MMIO_VERSION) != 2 ||
    80006480:	100017b7          	lui	a5,0x10001
    80006484:	43dc                	lw	a5,4(a5)
    80006486:	2781                	sext.w	a5,a5
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80006488:	4709                	li	a4,2
    8000648a:	14e79463          	bne	a5,a4,800065d2 <virtio_disk_init+0x18a>
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    8000648e:	100017b7          	lui	a5,0x10001
    80006492:	479c                	lw	a5,8(a5)
    80006494:	2781                	sext.w	a5,a5
     *R(VIRTIO_MMIO_VERSION) != 2 ||
    80006496:	12e79e63          	bne	a5,a4,800065d2 <virtio_disk_init+0x18a>
     *R(VIRTIO_MMIO_VENDOR_ID) != 0x554d4551){
    8000649a:	100017b7          	lui	a5,0x10001
    8000649e:	47d8                	lw	a4,12(a5)
    800064a0:	2701                	sext.w	a4,a4
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    800064a2:	554d47b7          	lui	a5,0x554d4
    800064a6:	55178793          	addi	a5,a5,1361 # 554d4551 <_entry-0x2ab2baaf>
    800064aa:	12f71463          	bne	a4,a5,800065d2 <virtio_disk_init+0x18a>
  *R(VIRTIO_MMIO_STATUS) = status;
    800064ae:	100017b7          	lui	a5,0x10001
    800064b2:	0607a823          	sw	zero,112(a5) # 10001070 <_entry-0x6fffef90>
  *R(VIRTIO_MMIO_STATUS) = status;
    800064b6:	4705                	li	a4,1
    800064b8:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    800064ba:	470d                	li	a4,3
    800064bc:	dbb8                	sw	a4,112(a5)
  uint64 features = *R(VIRTIO_MMIO_DEVICE_FEATURES);
    800064be:	4b98                	lw	a4,16(a5)
  *R(VIRTIO_MMIO_DRIVER_FEATURES) = features;
    800064c0:	c7ffe6b7          	lui	a3,0xc7ffe
    800064c4:	75f68693          	addi	a3,a3,1887 # ffffffffc7ffe75f <end+0xffffffff47fdbbdf>
    800064c8:	8f75                	and	a4,a4,a3
    800064ca:	d398                	sw	a4,32(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    800064cc:	472d                	li	a4,11
    800064ce:	dbb8                	sw	a4,112(a5)
  status = *R(VIRTIO_MMIO_STATUS);
    800064d0:	5bbc                	lw	a5,112(a5)
    800064d2:	0007891b          	sext.w	s2,a5
  if(!(status & VIRTIO_CONFIG_S_FEATURES_OK))
    800064d6:	8ba1                	andi	a5,a5,8
    800064d8:	10078563          	beqz	a5,800065e2 <virtio_disk_init+0x19a>
  *R(VIRTIO_MMIO_QUEUE_SEL) = 0;
    800064dc:	100017b7          	lui	a5,0x10001
    800064e0:	0207a823          	sw	zero,48(a5) # 10001030 <_entry-0x6fffefd0>
  if(*R(VIRTIO_MMIO_QUEUE_READY))
    800064e4:	43fc                	lw	a5,68(a5)
    800064e6:	2781                	sext.w	a5,a5
    800064e8:	10079563          	bnez	a5,800065f2 <virtio_disk_init+0x1aa>
  uint32 max = *R(VIRTIO_MMIO_QUEUE_NUM_MAX);
    800064ec:	100017b7          	lui	a5,0x10001
    800064f0:	5bdc                	lw	a5,52(a5)
    800064f2:	2781                	sext.w	a5,a5
  if(max == 0)
    800064f4:	10078763          	beqz	a5,80006602 <virtio_disk_init+0x1ba>
  if(max < NUM)
    800064f8:	471d                	li	a4,7
    800064fa:	10f77c63          	bgeu	a4,a5,80006612 <virtio_disk_init+0x1ca>
  disk.desc = kalloc();
    800064fe:	ffffa097          	auipc	ra,0xffffa
    80006502:	5e8080e7          	jalr	1512(ra) # 80000ae6 <kalloc>
    80006506:	0001c497          	auipc	s1,0x1c
    8000650a:	53a48493          	addi	s1,s1,1338 # 80022a40 <disk>
    8000650e:	e088                	sd	a0,0(s1)
  disk.avail = kalloc();
    80006510:	ffffa097          	auipc	ra,0xffffa
    80006514:	5d6080e7          	jalr	1494(ra) # 80000ae6 <kalloc>
    80006518:	e488                	sd	a0,8(s1)
  disk.used = kalloc();
    8000651a:	ffffa097          	auipc	ra,0xffffa
    8000651e:	5cc080e7          	jalr	1484(ra) # 80000ae6 <kalloc>
    80006522:	87aa                	mv	a5,a0
    80006524:	e888                	sd	a0,16(s1)
  if(!disk.desc || !disk.avail || !disk.used)
    80006526:	6088                	ld	a0,0(s1)
    80006528:	cd6d                	beqz	a0,80006622 <virtio_disk_init+0x1da>
    8000652a:	0001c717          	auipc	a4,0x1c
    8000652e:	51e73703          	ld	a4,1310(a4) # 80022a48 <disk+0x8>
    80006532:	cb65                	beqz	a4,80006622 <virtio_disk_init+0x1da>
    80006534:	c7fd                	beqz	a5,80006622 <virtio_disk_init+0x1da>
  memset(disk.desc, 0, PGSIZE);
    80006536:	6605                	lui	a2,0x1
    80006538:	4581                	li	a1,0
    8000653a:	ffffa097          	auipc	ra,0xffffa
    8000653e:	798080e7          	jalr	1944(ra) # 80000cd2 <memset>
  memset(disk.avail, 0, PGSIZE);
    80006542:	0001c497          	auipc	s1,0x1c
    80006546:	4fe48493          	addi	s1,s1,1278 # 80022a40 <disk>
    8000654a:	6605                	lui	a2,0x1
    8000654c:	4581                	li	a1,0
    8000654e:	6488                	ld	a0,8(s1)
    80006550:	ffffa097          	auipc	ra,0xffffa
    80006554:	782080e7          	jalr	1922(ra) # 80000cd2 <memset>
  memset(disk.used, 0, PGSIZE);
    80006558:	6605                	lui	a2,0x1
    8000655a:	4581                	li	a1,0
    8000655c:	6888                	ld	a0,16(s1)
    8000655e:	ffffa097          	auipc	ra,0xffffa
    80006562:	774080e7          	jalr	1908(ra) # 80000cd2 <memset>
  *R(VIRTIO_MMIO_QUEUE_NUM) = NUM;
    80006566:	100017b7          	lui	a5,0x10001
    8000656a:	4721                	li	a4,8
    8000656c:	df98                	sw	a4,56(a5)
  *R(VIRTIO_MMIO_QUEUE_DESC_LOW) = (uint64)disk.desc;
    8000656e:	4098                	lw	a4,0(s1)
    80006570:	08e7a023          	sw	a4,128(a5) # 10001080 <_entry-0x6fffef80>
  *R(VIRTIO_MMIO_QUEUE_DESC_HIGH) = (uint64)disk.desc >> 32;
    80006574:	40d8                	lw	a4,4(s1)
    80006576:	08e7a223          	sw	a4,132(a5)
  *R(VIRTIO_MMIO_DRIVER_DESC_LOW) = (uint64)disk.avail;
    8000657a:	6498                	ld	a4,8(s1)
    8000657c:	0007069b          	sext.w	a3,a4
    80006580:	08d7a823          	sw	a3,144(a5)
  *R(VIRTIO_MMIO_DRIVER_DESC_HIGH) = (uint64)disk.avail >> 32;
    80006584:	9701                	srai	a4,a4,0x20
    80006586:	08e7aa23          	sw	a4,148(a5)
  *R(VIRTIO_MMIO_DEVICE_DESC_LOW) = (uint64)disk.used;
    8000658a:	6898                	ld	a4,16(s1)
    8000658c:	0007069b          	sext.w	a3,a4
    80006590:	0ad7a023          	sw	a3,160(a5)
  *R(VIRTIO_MMIO_DEVICE_DESC_HIGH) = (uint64)disk.used >> 32;
    80006594:	9701                	srai	a4,a4,0x20
    80006596:	0ae7a223          	sw	a4,164(a5)
  *R(VIRTIO_MMIO_QUEUE_READY) = 0x1;
    8000659a:	4705                	li	a4,1
    8000659c:	c3f8                	sw	a4,68(a5)
    disk.free[i] = 1;
    8000659e:	00e48c23          	sb	a4,24(s1)
    800065a2:	00e48ca3          	sb	a4,25(s1)
    800065a6:	00e48d23          	sb	a4,26(s1)
    800065aa:	00e48da3          	sb	a4,27(s1)
    800065ae:	00e48e23          	sb	a4,28(s1)
    800065b2:	00e48ea3          	sb	a4,29(s1)
    800065b6:	00e48f23          	sb	a4,30(s1)
    800065ba:	00e48fa3          	sb	a4,31(s1)
  status |= VIRTIO_CONFIG_S_DRIVER_OK;
    800065be:	00496913          	ori	s2,s2,4
  *R(VIRTIO_MMIO_STATUS) = status;
    800065c2:	0727a823          	sw	s2,112(a5)
}
    800065c6:	60e2                	ld	ra,24(sp)
    800065c8:	6442                	ld	s0,16(sp)
    800065ca:	64a2                	ld	s1,8(sp)
    800065cc:	6902                	ld	s2,0(sp)
    800065ce:	6105                	addi	sp,sp,32
    800065d0:	8082                	ret
    panic("could not find virtio disk");
    800065d2:	00002517          	auipc	a0,0x2
    800065d6:	1be50513          	addi	a0,a0,446 # 80008790 <syscalls+0x340>
    800065da:	ffffa097          	auipc	ra,0xffffa
    800065de:	f66080e7          	jalr	-154(ra) # 80000540 <panic>
    panic("virtio disk FEATURES_OK unset");
    800065e2:	00002517          	auipc	a0,0x2
    800065e6:	1ce50513          	addi	a0,a0,462 # 800087b0 <syscalls+0x360>
    800065ea:	ffffa097          	auipc	ra,0xffffa
    800065ee:	f56080e7          	jalr	-170(ra) # 80000540 <panic>
    panic("virtio disk should not be ready");
    800065f2:	00002517          	auipc	a0,0x2
    800065f6:	1de50513          	addi	a0,a0,478 # 800087d0 <syscalls+0x380>
    800065fa:	ffffa097          	auipc	ra,0xffffa
    800065fe:	f46080e7          	jalr	-186(ra) # 80000540 <panic>
    panic("virtio disk has no queue 0");
    80006602:	00002517          	auipc	a0,0x2
    80006606:	1ee50513          	addi	a0,a0,494 # 800087f0 <syscalls+0x3a0>
    8000660a:	ffffa097          	auipc	ra,0xffffa
    8000660e:	f36080e7          	jalr	-202(ra) # 80000540 <panic>
    panic("virtio disk max queue too short");
    80006612:	00002517          	auipc	a0,0x2
    80006616:	1fe50513          	addi	a0,a0,510 # 80008810 <syscalls+0x3c0>
    8000661a:	ffffa097          	auipc	ra,0xffffa
    8000661e:	f26080e7          	jalr	-218(ra) # 80000540 <panic>
    panic("virtio disk kalloc");
    80006622:	00002517          	auipc	a0,0x2
    80006626:	20e50513          	addi	a0,a0,526 # 80008830 <syscalls+0x3e0>
    8000662a:	ffffa097          	auipc	ra,0xffffa
    8000662e:	f16080e7          	jalr	-234(ra) # 80000540 <panic>

0000000080006632 <virtio_disk_rw>:
  return 0;
}

void
virtio_disk_rw(struct buf *b, int write)
{
    80006632:	7119                	addi	sp,sp,-128
    80006634:	fc86                	sd	ra,120(sp)
    80006636:	f8a2                	sd	s0,112(sp)
    80006638:	f4a6                	sd	s1,104(sp)
    8000663a:	f0ca                	sd	s2,96(sp)
    8000663c:	ecce                	sd	s3,88(sp)
    8000663e:	e8d2                	sd	s4,80(sp)
    80006640:	e4d6                	sd	s5,72(sp)
    80006642:	e0da                	sd	s6,64(sp)
    80006644:	fc5e                	sd	s7,56(sp)
    80006646:	f862                	sd	s8,48(sp)
    80006648:	f466                	sd	s9,40(sp)
    8000664a:	f06a                	sd	s10,32(sp)
    8000664c:	ec6e                	sd	s11,24(sp)
    8000664e:	0100                	addi	s0,sp,128
    80006650:	8aaa                	mv	s5,a0
    80006652:	8c2e                	mv	s8,a1
  uint64 sector = b->blockno * (BSIZE / 512);
    80006654:	00c52d03          	lw	s10,12(a0)
    80006658:	001d1d1b          	slliw	s10,s10,0x1
    8000665c:	1d02                	slli	s10,s10,0x20
    8000665e:	020d5d13          	srli	s10,s10,0x20

  acquire(&disk.vdisk_lock);
    80006662:	0001c517          	auipc	a0,0x1c
    80006666:	50650513          	addi	a0,a0,1286 # 80022b68 <disk+0x128>
    8000666a:	ffffa097          	auipc	ra,0xffffa
    8000666e:	56c080e7          	jalr	1388(ra) # 80000bd6 <acquire>
  for(int i = 0; i < 3; i++){
    80006672:	4981                	li	s3,0
  for(int i = 0; i < NUM; i++){
    80006674:	44a1                	li	s1,8
      disk.free[i] = 0;
    80006676:	0001cb97          	auipc	s7,0x1c
    8000667a:	3cab8b93          	addi	s7,s7,970 # 80022a40 <disk>
  for(int i = 0; i < 3; i++){
    8000667e:	4b0d                	li	s6,3
  int idx[3];
  while(1){
    if(alloc3_desc(idx) == 0) {
      break;
    }
    sleep(&disk.free[0], &disk.vdisk_lock);
    80006680:	0001cc97          	auipc	s9,0x1c
    80006684:	4e8c8c93          	addi	s9,s9,1256 # 80022b68 <disk+0x128>
    80006688:	a08d                	j	800066ea <virtio_disk_rw+0xb8>
      disk.free[i] = 0;
    8000668a:	00fb8733          	add	a4,s7,a5
    8000668e:	00070c23          	sb	zero,24(a4)
    idx[i] = alloc_desc();
    80006692:	c19c                	sw	a5,0(a1)
    if(idx[i] < 0){
    80006694:	0207c563          	bltz	a5,800066be <virtio_disk_rw+0x8c>
  for(int i = 0; i < 3; i++){
    80006698:	2905                	addiw	s2,s2,1
    8000669a:	0611                	addi	a2,a2,4 # 1004 <_entry-0x7fffeffc>
    8000669c:	05690c63          	beq	s2,s6,800066f4 <virtio_disk_rw+0xc2>
    idx[i] = alloc_desc();
    800066a0:	85b2                	mv	a1,a2
  for(int i = 0; i < NUM; i++){
    800066a2:	0001c717          	auipc	a4,0x1c
    800066a6:	39e70713          	addi	a4,a4,926 # 80022a40 <disk>
    800066aa:	87ce                	mv	a5,s3
    if(disk.free[i]){
    800066ac:	01874683          	lbu	a3,24(a4)
    800066b0:	fee9                	bnez	a3,8000668a <virtio_disk_rw+0x58>
  for(int i = 0; i < NUM; i++){
    800066b2:	2785                	addiw	a5,a5,1
    800066b4:	0705                	addi	a4,a4,1
    800066b6:	fe979be3          	bne	a5,s1,800066ac <virtio_disk_rw+0x7a>
    idx[i] = alloc_desc();
    800066ba:	57fd                	li	a5,-1
    800066bc:	c19c                	sw	a5,0(a1)
      for(int j = 0; j < i; j++)
    800066be:	01205d63          	blez	s2,800066d8 <virtio_disk_rw+0xa6>
    800066c2:	8dce                	mv	s11,s3
        free_desc(idx[j]);
    800066c4:	000a2503          	lw	a0,0(s4)
    800066c8:	00000097          	auipc	ra,0x0
    800066cc:	cfe080e7          	jalr	-770(ra) # 800063c6 <free_desc>
      for(int j = 0; j < i; j++)
    800066d0:	2d85                	addiw	s11,s11,1
    800066d2:	0a11                	addi	s4,s4,4
    800066d4:	ff2d98e3          	bne	s11,s2,800066c4 <virtio_disk_rw+0x92>
    sleep(&disk.free[0], &disk.vdisk_lock);
    800066d8:	85e6                	mv	a1,s9
    800066da:	0001c517          	auipc	a0,0x1c
    800066de:	37e50513          	addi	a0,a0,894 # 80022a58 <disk+0x18>
    800066e2:	ffffc097          	auipc	ra,0xffffc
    800066e6:	a36080e7          	jalr	-1482(ra) # 80002118 <sleep>
  for(int i = 0; i < 3; i++){
    800066ea:	f8040a13          	addi	s4,s0,-128
{
    800066ee:	8652                	mv	a2,s4
  for(int i = 0; i < 3; i++){
    800066f0:	894e                	mv	s2,s3
    800066f2:	b77d                	j	800066a0 <virtio_disk_rw+0x6e>
  }

  // format the three descriptors.
  // qemu's virtio-blk.c reads them.

  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    800066f4:	f8042503          	lw	a0,-128(s0)
    800066f8:	00a50713          	addi	a4,a0,10
    800066fc:	0712                	slli	a4,a4,0x4

  if(write)
    800066fe:	0001c797          	auipc	a5,0x1c
    80006702:	34278793          	addi	a5,a5,834 # 80022a40 <disk>
    80006706:	00e786b3          	add	a3,a5,a4
    8000670a:	01803633          	snez	a2,s8
    8000670e:	c690                	sw	a2,8(a3)
    buf0->type = VIRTIO_BLK_T_OUT; // write the disk
  else
    buf0->type = VIRTIO_BLK_T_IN; // read the disk
  buf0->reserved = 0;
    80006710:	0006a623          	sw	zero,12(a3)
  buf0->sector = sector;
    80006714:	01a6b823          	sd	s10,16(a3)

  disk.desc[idx[0]].addr = (uint64) buf0;
    80006718:	f6070613          	addi	a2,a4,-160
    8000671c:	6394                	ld	a3,0(a5)
    8000671e:	96b2                	add	a3,a3,a2
  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    80006720:	00870593          	addi	a1,a4,8
    80006724:	95be                	add	a1,a1,a5
  disk.desc[idx[0]].addr = (uint64) buf0;
    80006726:	e28c                	sd	a1,0(a3)
  disk.desc[idx[0]].len = sizeof(struct virtio_blk_req);
    80006728:	0007b803          	ld	a6,0(a5)
    8000672c:	9642                	add	a2,a2,a6
    8000672e:	46c1                	li	a3,16
    80006730:	c614                	sw	a3,8(a2)
  disk.desc[idx[0]].flags = VRING_DESC_F_NEXT;
    80006732:	4585                	li	a1,1
    80006734:	00b61623          	sh	a1,12(a2)
  disk.desc[idx[0]].next = idx[1];
    80006738:	f8442683          	lw	a3,-124(s0)
    8000673c:	00d61723          	sh	a3,14(a2)

  disk.desc[idx[1]].addr = (uint64) b->data;
    80006740:	0692                	slli	a3,a3,0x4
    80006742:	9836                	add	a6,a6,a3
    80006744:	058a8613          	addi	a2,s5,88
    80006748:	00c83023          	sd	a2,0(a6)
  disk.desc[idx[1]].len = BSIZE;
    8000674c:	0007b803          	ld	a6,0(a5)
    80006750:	96c2                	add	a3,a3,a6
    80006752:	40000613          	li	a2,1024
    80006756:	c690                	sw	a2,8(a3)
  if(write)
    80006758:	001c3613          	seqz	a2,s8
    8000675c:	0016161b          	slliw	a2,a2,0x1
    disk.desc[idx[1]].flags = 0; // device reads b->data
  else
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
  disk.desc[idx[1]].flags |= VRING_DESC_F_NEXT;
    80006760:	00166613          	ori	a2,a2,1
    80006764:	00c69623          	sh	a2,12(a3)
  disk.desc[idx[1]].next = idx[2];
    80006768:	f8842603          	lw	a2,-120(s0)
    8000676c:	00c69723          	sh	a2,14(a3)

  disk.info[idx[0]].status = 0xff; // device writes 0 on success
    80006770:	00250693          	addi	a3,a0,2
    80006774:	0692                	slli	a3,a3,0x4
    80006776:	96be                	add	a3,a3,a5
    80006778:	58fd                	li	a7,-1
    8000677a:	01168823          	sb	a7,16(a3)
  disk.desc[idx[2]].addr = (uint64) &disk.info[idx[0]].status;
    8000677e:	0612                	slli	a2,a2,0x4
    80006780:	9832                	add	a6,a6,a2
    80006782:	f9070713          	addi	a4,a4,-112
    80006786:	973e                	add	a4,a4,a5
    80006788:	00e83023          	sd	a4,0(a6)
  disk.desc[idx[2]].len = 1;
    8000678c:	6398                	ld	a4,0(a5)
    8000678e:	9732                	add	a4,a4,a2
    80006790:	c70c                	sw	a1,8(a4)
  disk.desc[idx[2]].flags = VRING_DESC_F_WRITE; // device writes the status
    80006792:	4609                	li	a2,2
    80006794:	00c71623          	sh	a2,12(a4)
  disk.desc[idx[2]].next = 0;
    80006798:	00071723          	sh	zero,14(a4)

  // record struct buf for virtio_disk_intr().
  b->disk = 1;
    8000679c:	00baa223          	sw	a1,4(s5)
  disk.info[idx[0]].b = b;
    800067a0:	0156b423          	sd	s5,8(a3)

  // tell the device the first index in our chain of descriptors.
  disk.avail->ring[disk.avail->idx % NUM] = idx[0];
    800067a4:	6794                	ld	a3,8(a5)
    800067a6:	0026d703          	lhu	a4,2(a3)
    800067aa:	8b1d                	andi	a4,a4,7
    800067ac:	0706                	slli	a4,a4,0x1
    800067ae:	96ba                	add	a3,a3,a4
    800067b0:	00a69223          	sh	a0,4(a3)

  __sync_synchronize();
    800067b4:	0ff0000f          	fence

  // tell the device another avail ring entry is available.
  disk.avail->idx += 1; // not % NUM ...
    800067b8:	6798                	ld	a4,8(a5)
    800067ba:	00275783          	lhu	a5,2(a4)
    800067be:	2785                	addiw	a5,a5,1
    800067c0:	00f71123          	sh	a5,2(a4)

  __sync_synchronize();
    800067c4:	0ff0000f          	fence

  *R(VIRTIO_MMIO_QUEUE_NOTIFY) = 0; // value is queue number
    800067c8:	100017b7          	lui	a5,0x10001
    800067cc:	0407a823          	sw	zero,80(a5) # 10001050 <_entry-0x6fffefb0>

  // Wait for virtio_disk_intr() to say request has finished.
  while(b->disk == 1) {
    800067d0:	004aa783          	lw	a5,4(s5)
    sleep(b, &disk.vdisk_lock);
    800067d4:	0001c917          	auipc	s2,0x1c
    800067d8:	39490913          	addi	s2,s2,916 # 80022b68 <disk+0x128>
  while(b->disk == 1) {
    800067dc:	4485                	li	s1,1
    800067de:	00b79c63          	bne	a5,a1,800067f6 <virtio_disk_rw+0x1c4>
    sleep(b, &disk.vdisk_lock);
    800067e2:	85ca                	mv	a1,s2
    800067e4:	8556                	mv	a0,s5
    800067e6:	ffffc097          	auipc	ra,0xffffc
    800067ea:	932080e7          	jalr	-1742(ra) # 80002118 <sleep>
  while(b->disk == 1) {
    800067ee:	004aa783          	lw	a5,4(s5)
    800067f2:	fe9788e3          	beq	a5,s1,800067e2 <virtio_disk_rw+0x1b0>
  }

  disk.info[idx[0]].b = 0;
    800067f6:	f8042903          	lw	s2,-128(s0)
    800067fa:	00290713          	addi	a4,s2,2
    800067fe:	0712                	slli	a4,a4,0x4
    80006800:	0001c797          	auipc	a5,0x1c
    80006804:	24078793          	addi	a5,a5,576 # 80022a40 <disk>
    80006808:	97ba                	add	a5,a5,a4
    8000680a:	0007b423          	sd	zero,8(a5)
    int flag = disk.desc[i].flags;
    8000680e:	0001c997          	auipc	s3,0x1c
    80006812:	23298993          	addi	s3,s3,562 # 80022a40 <disk>
    80006816:	00491713          	slli	a4,s2,0x4
    8000681a:	0009b783          	ld	a5,0(s3)
    8000681e:	97ba                	add	a5,a5,a4
    80006820:	00c7d483          	lhu	s1,12(a5)
    int nxt = disk.desc[i].next;
    80006824:	854a                	mv	a0,s2
    80006826:	00e7d903          	lhu	s2,14(a5)
    free_desc(i);
    8000682a:	00000097          	auipc	ra,0x0
    8000682e:	b9c080e7          	jalr	-1124(ra) # 800063c6 <free_desc>
    if(flag & VRING_DESC_F_NEXT)
    80006832:	8885                	andi	s1,s1,1
    80006834:	f0ed                	bnez	s1,80006816 <virtio_disk_rw+0x1e4>
  free_chain(idx[0]);

  release(&disk.vdisk_lock);
    80006836:	0001c517          	auipc	a0,0x1c
    8000683a:	33250513          	addi	a0,a0,818 # 80022b68 <disk+0x128>
    8000683e:	ffffa097          	auipc	ra,0xffffa
    80006842:	44c080e7          	jalr	1100(ra) # 80000c8a <release>
}
    80006846:	70e6                	ld	ra,120(sp)
    80006848:	7446                	ld	s0,112(sp)
    8000684a:	74a6                	ld	s1,104(sp)
    8000684c:	7906                	ld	s2,96(sp)
    8000684e:	69e6                	ld	s3,88(sp)
    80006850:	6a46                	ld	s4,80(sp)
    80006852:	6aa6                	ld	s5,72(sp)
    80006854:	6b06                	ld	s6,64(sp)
    80006856:	7be2                	ld	s7,56(sp)
    80006858:	7c42                	ld	s8,48(sp)
    8000685a:	7ca2                	ld	s9,40(sp)
    8000685c:	7d02                	ld	s10,32(sp)
    8000685e:	6de2                	ld	s11,24(sp)
    80006860:	6109                	addi	sp,sp,128
    80006862:	8082                	ret

0000000080006864 <virtio_disk_intr>:

void
virtio_disk_intr()
{
    80006864:	1101                	addi	sp,sp,-32
    80006866:	ec06                	sd	ra,24(sp)
    80006868:	e822                	sd	s0,16(sp)
    8000686a:	e426                	sd	s1,8(sp)
    8000686c:	1000                	addi	s0,sp,32
  acquire(&disk.vdisk_lock);
    8000686e:	0001c497          	auipc	s1,0x1c
    80006872:	1d248493          	addi	s1,s1,466 # 80022a40 <disk>
    80006876:	0001c517          	auipc	a0,0x1c
    8000687a:	2f250513          	addi	a0,a0,754 # 80022b68 <disk+0x128>
    8000687e:	ffffa097          	auipc	ra,0xffffa
    80006882:	358080e7          	jalr	856(ra) # 80000bd6 <acquire>
  // we've seen this interrupt, which the following line does.
  // this may race with the device writing new entries to
  // the "used" ring, in which case we may process the new
  // completion entries in this interrupt, and have nothing to do
  // in the next interrupt, which is harmless.
  *R(VIRTIO_MMIO_INTERRUPT_ACK) = *R(VIRTIO_MMIO_INTERRUPT_STATUS) & 0x3;
    80006886:	10001737          	lui	a4,0x10001
    8000688a:	533c                	lw	a5,96(a4)
    8000688c:	8b8d                	andi	a5,a5,3
    8000688e:	d37c                	sw	a5,100(a4)

  __sync_synchronize();
    80006890:	0ff0000f          	fence

  // the device increments disk.used->idx when it
  // adds an entry to the used ring.

  while(disk.used_idx != disk.used->idx){
    80006894:	689c                	ld	a5,16(s1)
    80006896:	0204d703          	lhu	a4,32(s1)
    8000689a:	0027d783          	lhu	a5,2(a5)
    8000689e:	04f70863          	beq	a4,a5,800068ee <virtio_disk_intr+0x8a>
    __sync_synchronize();
    800068a2:	0ff0000f          	fence
    int id = disk.used->ring[disk.used_idx % NUM].id;
    800068a6:	6898                	ld	a4,16(s1)
    800068a8:	0204d783          	lhu	a5,32(s1)
    800068ac:	8b9d                	andi	a5,a5,7
    800068ae:	078e                	slli	a5,a5,0x3
    800068b0:	97ba                	add	a5,a5,a4
    800068b2:	43dc                	lw	a5,4(a5)

    if(disk.info[id].status != 0)
    800068b4:	00278713          	addi	a4,a5,2
    800068b8:	0712                	slli	a4,a4,0x4
    800068ba:	9726                	add	a4,a4,s1
    800068bc:	01074703          	lbu	a4,16(a4) # 10001010 <_entry-0x6fffeff0>
    800068c0:	e721                	bnez	a4,80006908 <virtio_disk_intr+0xa4>
      panic("virtio_disk_intr status");

    struct buf *b = disk.info[id].b;
    800068c2:	0789                	addi	a5,a5,2
    800068c4:	0792                	slli	a5,a5,0x4
    800068c6:	97a6                	add	a5,a5,s1
    800068c8:	6788                	ld	a0,8(a5)
    b->disk = 0;   // disk is done with buf
    800068ca:	00052223          	sw	zero,4(a0)
    wakeup(b);
    800068ce:	ffffc097          	auipc	ra,0xffffc
    800068d2:	8ae080e7          	jalr	-1874(ra) # 8000217c <wakeup>

    disk.used_idx += 1;
    800068d6:	0204d783          	lhu	a5,32(s1)
    800068da:	2785                	addiw	a5,a5,1
    800068dc:	17c2                	slli	a5,a5,0x30
    800068de:	93c1                	srli	a5,a5,0x30
    800068e0:	02f49023          	sh	a5,32(s1)
  while(disk.used_idx != disk.used->idx){
    800068e4:	6898                	ld	a4,16(s1)
    800068e6:	00275703          	lhu	a4,2(a4)
    800068ea:	faf71ce3          	bne	a4,a5,800068a2 <virtio_disk_intr+0x3e>
  }

  release(&disk.vdisk_lock);
    800068ee:	0001c517          	auipc	a0,0x1c
    800068f2:	27a50513          	addi	a0,a0,634 # 80022b68 <disk+0x128>
    800068f6:	ffffa097          	auipc	ra,0xffffa
    800068fa:	394080e7          	jalr	916(ra) # 80000c8a <release>
}
    800068fe:	60e2                	ld	ra,24(sp)
    80006900:	6442                	ld	s0,16(sp)
    80006902:	64a2                	ld	s1,8(sp)
    80006904:	6105                	addi	sp,sp,32
    80006906:	8082                	ret
      panic("virtio_disk_intr status");
    80006908:	00002517          	auipc	a0,0x2
    8000690c:	f4050513          	addi	a0,a0,-192 # 80008848 <syscalls+0x3f8>
    80006910:	ffffa097          	auipc	ra,0xffffa
    80006914:	c30080e7          	jalr	-976(ra) # 80000540 <panic>
	...

0000000080007000 <_trampoline>:
    80007000:	14051073          	csrw	sscratch,a0
    80007004:	02000537          	lui	a0,0x2000
    80007008:	357d                	addiw	a0,a0,-1 # 1ffffff <_entry-0x7e000001>
    8000700a:	0536                	slli	a0,a0,0xd
    8000700c:	02153423          	sd	ra,40(a0)
    80007010:	02253823          	sd	sp,48(a0)
    80007014:	02353c23          	sd	gp,56(a0)
    80007018:	04453023          	sd	tp,64(a0)
    8000701c:	04553423          	sd	t0,72(a0)
    80007020:	04653823          	sd	t1,80(a0)
    80007024:	04753c23          	sd	t2,88(a0)
    80007028:	f120                	sd	s0,96(a0)
    8000702a:	f524                	sd	s1,104(a0)
    8000702c:	fd2c                	sd	a1,120(a0)
    8000702e:	e150                	sd	a2,128(a0)
    80007030:	e554                	sd	a3,136(a0)
    80007032:	e958                	sd	a4,144(a0)
    80007034:	ed5c                	sd	a5,152(a0)
    80007036:	0b053023          	sd	a6,160(a0)
    8000703a:	0b153423          	sd	a7,168(a0)
    8000703e:	0b253823          	sd	s2,176(a0)
    80007042:	0b353c23          	sd	s3,184(a0)
    80007046:	0d453023          	sd	s4,192(a0)
    8000704a:	0d553423          	sd	s5,200(a0)
    8000704e:	0d653823          	sd	s6,208(a0)
    80007052:	0d753c23          	sd	s7,216(a0)
    80007056:	0f853023          	sd	s8,224(a0)
    8000705a:	0f953423          	sd	s9,232(a0)
    8000705e:	0fa53823          	sd	s10,240(a0)
    80007062:	0fb53c23          	sd	s11,248(a0)
    80007066:	11c53023          	sd	t3,256(a0)
    8000706a:	11d53423          	sd	t4,264(a0)
    8000706e:	11e53823          	sd	t5,272(a0)
    80007072:	11f53c23          	sd	t6,280(a0)
    80007076:	140022f3          	csrr	t0,sscratch
    8000707a:	06553823          	sd	t0,112(a0)
    8000707e:	00853103          	ld	sp,8(a0)
    80007082:	02053203          	ld	tp,32(a0)
    80007086:	01053283          	ld	t0,16(a0)
    8000708a:	00053303          	ld	t1,0(a0)
    8000708e:	12000073          	sfence.vma
    80007092:	18031073          	csrw	satp,t1
    80007096:	12000073          	sfence.vma
    8000709a:	8282                	jr	t0

000000008000709c <userret>:
    8000709c:	12000073          	sfence.vma
    800070a0:	18051073          	csrw	satp,a0
    800070a4:	12000073          	sfence.vma
    800070a8:	02000537          	lui	a0,0x2000
    800070ac:	357d                	addiw	a0,a0,-1 # 1ffffff <_entry-0x7e000001>
    800070ae:	0536                	slli	a0,a0,0xd
    800070b0:	02853083          	ld	ra,40(a0)
    800070b4:	03053103          	ld	sp,48(a0)
    800070b8:	03853183          	ld	gp,56(a0)
    800070bc:	04053203          	ld	tp,64(a0)
    800070c0:	04853283          	ld	t0,72(a0)
    800070c4:	05053303          	ld	t1,80(a0)
    800070c8:	05853383          	ld	t2,88(a0)
    800070cc:	7120                	ld	s0,96(a0)
    800070ce:	7524                	ld	s1,104(a0)
    800070d0:	7d2c                	ld	a1,120(a0)
    800070d2:	6150                	ld	a2,128(a0)
    800070d4:	6554                	ld	a3,136(a0)
    800070d6:	6958                	ld	a4,144(a0)
    800070d8:	6d5c                	ld	a5,152(a0)
    800070da:	0a053803          	ld	a6,160(a0)
    800070de:	0a853883          	ld	a7,168(a0)
    800070e2:	0b053903          	ld	s2,176(a0)
    800070e6:	0b853983          	ld	s3,184(a0)
    800070ea:	0c053a03          	ld	s4,192(a0)
    800070ee:	0c853a83          	ld	s5,200(a0)
    800070f2:	0d053b03          	ld	s6,208(a0)
    800070f6:	0d853b83          	ld	s7,216(a0)
    800070fa:	0e053c03          	ld	s8,224(a0)
    800070fe:	0e853c83          	ld	s9,232(a0)
    80007102:	0f053d03          	ld	s10,240(a0)
    80007106:	0f853d83          	ld	s11,248(a0)
    8000710a:	10053e03          	ld	t3,256(a0)
    8000710e:	10853e83          	ld	t4,264(a0)
    80007112:	11053f03          	ld	t5,272(a0)
    80007116:	11853f83          	ld	t6,280(a0)
    8000711a:	7928                	ld	a0,112(a0)
    8000711c:	10200073          	sret
	...
