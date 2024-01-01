# bouncing square test

import random
import sys

import pygame # conda install -c cogsci pygame

width, height = 320, 200
square_width = 25
position = [10, 10]
velocity = [1, 1]
square_color = (255, 0, 0)

pygame.init()
screen = pygame.display.set_mode((width, height))
pygame.display.set_caption('Bouncing Square')
clock = pygame.time.Clock()

def rand_color():
    return (random.randrange(255), random.randrange(255), random.randrange(255))

while True:
    for event in pygame.event.get():
        if event.type == pygame.QUIT:
            pygame.quit()
            sys.exit()

    # check square hits left or right bound
    if position[0] <= 0 or position[0] >= width - square_width:
        velocity[0] = -velocity[0]
        square_color = rand_color()

    # check square hits bottom or top bound
    if position[1] <= 0 or position[1] >= height - square_width:
        velocity[1] = -velocity[1]
        square_color = rand_color()

    # move square based on velocity
    position[0] += velocity[0]
    position[1] += velocity[1]

    screen.fill((0, 0, 0))
    pygame.draw.rect(screen, square_color, (position[0], position[1], square_width, square_width))
    pygame.display.flip()
    clock.tick(60)
