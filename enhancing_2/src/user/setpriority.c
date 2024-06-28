#include "kernel/types.h"
#include "kernel/stat.h"
#include "user/user.h"

int main(int argc, char **argv)
{
    if (argc != 3)
    {
        fprintf(2, "usage : setpriority priority pid\n");
        exit(1);
    }
    int pid = atoi(argv[1]);
    int priority = atoi(argv[2]);
    set_priority(pid,priority);
    exit(0);
}