def transformit(x):
    val = int(x,16);

    return val/128 #if val < 32768 else val-65538/128

li = [	"0F30",
	"0F33",
	"0F32",
	"0F31",
	"0F34",
	"0F30",
	"0F31",
	"0F30",
        "7E20",
        "7E10",
        "7F30",
        "7F32",
        "7F31",
        "7F39",
        "7F37",
        "7F40",
        "7F39",
        "7F80"] 






for i in range(1,len(li)-7):
    sum = 0
    for l in li[i:i+8]:
        sum += transformit(l)
    print('Run '+str(i)+': ',end='')
    print(sum/8)
    print()

#print(sum/8)
