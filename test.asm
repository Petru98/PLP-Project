int x, y, z = 6;
const int a = 10, b = 13;

function f(int a)
{}

function sum(int x, int y)
{
    return x + y;
}

function main()
{
    int x, y;
    x = read();
    y = z;
    z = x + y;
    print("x = ", x, "\ny = ", y, "\nz = ", z, "\n");

    {
        int s;
        s = sum(x, y);
        print("s = ", s, "\nsum(x,y) = ", sum(x, y), "\n");
    }

    return z;
}
