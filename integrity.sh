import os

def run(user_input):
    os.system("ping " + user_input)  # ⚠️ CodeQL flags this
