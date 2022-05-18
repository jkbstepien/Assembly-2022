def solve_linear_function():
    a = int(input("Give a: "))
    b = int(input("Give b: "))

    map_width = 20
    map_height = 20
    ox = int((map_height - 1) / 2)
    oy = int((map_width - 1) / 2)

    y_b = b

    if a == 0:
        x_a = 0
    else:
        x_a = -b/a

    print(f"\nx = {x_a}")
    print(f"y = {y_b}\n")

    for ys in range(map_height):
        y_position = ys - ox
        for xs in range(map_width):
            x_position = xs - oy
            if a == 0 and y_position == -b:
                print("*", end='')
            elif a != 0 \
                    and b != 0 \
                    and (y_position - 0) * (0 - x_a) + (y_b - 0) * (x_position - x_a) == 0:
                print("*", end='')
            elif b == 0 and (y_position - 0) + (x_position - x_a) == 0:
                print("*", end='')
            elif ys == ox:
                print("#", end='')
            elif xs == oy:
                print("#", end='')
            else:
                print(" ", end='')
        print(end='\n')

    print(f"map width = {map_width}")
    print(f"map height = {map_height}")


if __name__ == '__main__':
    solve_linear_function()