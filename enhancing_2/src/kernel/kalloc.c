// Physical memory allocator, for user processes,
// kernel stacks, page-table pages,
// and pipe buffers. Allocates whole 4096-byte pages.

#include "types.h"
#include "param.h"
#include "memlayout.h"
#include "spinlock.h"
#include "riscv.h"
#include "defs.h"

void freerange(void *pa_start, void *pa_end);

extern char end[]; // first add_refress after kernel.
                   // defined by kernel.ld.

struct run
{
  struct run *next;
};

struct
{
  struct spinlock lock;
  struct run *freelist;
} kmem;

struct spinlock lock;
int refs[PGROUNDUP(PHYSTOP) / 4096];
void initialize()
{
  acquire(&lock);
  for (int i = 0; i < (PGROUNDUP(PHYSTOP) / 4096); ++i)
    refs[i] = 0;
  release(&lock);
}

void dec_ref(void *pa)
{
  acquire(&lock);
  if (refs[(uint64)pa / 4096] > 0)
  {
    refs[(uint64)pa / 4096] -= 1;
  }
  else
    panic("dec_ref");
  release(&lock);
}

void add_ref(void *pa)
{
  acquire(&lock);
  if (refs[(uint64)pa / 4096] >= 0)
  {
    refs[(uint64)pa / 4096] += 1;
  }
  else
    panic("add_ref");
  release(&lock);
}

void kinit()
{
  initlock(&lock, "init_fault");
  initialize();
  initlock(&kmem.lock, "kmem");
  freerange(end, (void *)PHYSTOP);
}

void freerange(void *pa_start, void *pa_end)
{
  char *p;
  p = (char *)PGROUNDUP((uint64)pa_start);
  for (; p + PGSIZE <= (char *)pa_end; p += PGSIZE)
  {
    add_ref(p);
    kfree(p);
  }
}

// Free the page of physical memory pointed at by pa,
// which normally should have been returned by a
// call to kalloc().  (The exception is when
// initializing the allocator; see kinit above.)
void kfree(void *pa)
{
  struct run *r;

  if (((uint64)pa % PGSIZE) != 0 || (char *)pa < end || (uint64)pa >= PHYSTOP)
    panic("kfree");

  dec_ref(pa);
  if (refs[(uint64)pa / 4096] > 0)
    return;
  // Fill with junk to catch dangling refss.
  memset(pa, 1, PGSIZE);

  r = (struct run *)pa;

  acquire(&kmem.lock);
  r->next = kmem.freelist;
  kmem.freelist = r;
  release(&kmem.lock);
}

// Allocate one 4096-byte page of physical memory.
// Returns a pointer that the kernel can use.
// Returns 0 if the memory cannot be allocated.
void *
kalloc(void)
{
  struct run *r;

  acquire(&kmem.lock);
  r = kmem.freelist;
  if (r)
    kmem.freelist = r->next;
  release(&kmem.lock);

  if (r)
  {
    memset((char *)r, 5, PGSIZE); // fill with junk
    add_ref((void *)r);
  }
  return (void *)r;
}
