\# Dungeoneers Godot Project ----NOW MADE WITH GODOT dont feel like correcting this yet -----



Welcome to the Dungeoneers repository! This project uses Git for version control.



\## Git Workflow Commands



Use the following sequence of commands in your project's root directory via Git Bash to save and upload changes:



git add .

git commit -m "whatever i changed or added"

git push origin master





This is a text adventure game. Your goal is to escape with or without the treasure.

All you have to do is type one of the directions to initiate an action.

    - north     - south     - east      - west

Type 'inventory' at any time to check what items you have.

Just double click the .exe file and enjoy!





If i were to do it again, i would use this idea as a starter to a text based dungeon crawler.

    - use the room building logic to create a much larger/diverse map

    - add player/enemy attribute values

    - add in classes and expand upon the inventory

    - lastly i would try adding actual combat sort of like Pokémon



Shortcomings:

    - dependence on 'continue'

        - without the continue i would need some type of Boolean to check if i want to redo the loop

    - also i forgot to add a checker to the monster room so if you go back in after defeating it you...lose.

        - i like it though cause why go back in there anyway?



Problems:

    - figuring out how to get the room to function as a list

    - figure out how to move through the main loop without stopping everything

    - crashes

        - fixed with the cleanup function

    - max items are iffy





