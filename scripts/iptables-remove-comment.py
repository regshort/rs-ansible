import os
import re

# path to the task files
task_path = '../playbooks/iptables/tasks'

# Regular expression pattern to match task lines
task_pattern = re.compile(r'^- name: (.*)$')

# Loop through all the task files
for filename in os.listdir(task_path):
    if filename.endswith('.yml'):
        file_path = os.path.join(task_path, filename)
        with open(file_path, 'r') as f:
            lines = f.readlines()
        
        # Loop through all the lines in the file
        i = 0
        while i < len(lines):
            match = task_pattern.match(lines[i])
            if match:
                # Check if the next line is a task definition
                if lines[i+1].strip().startswith('ansible.builtin.iptables:'):
                    j = i+1
                    # Loop through the following lines until a blank line is found
                    while j < len(lines) and lines[j].strip() != '':
                        if 'comment' in lines[j]:
                            # Delete the comment line
                            del lines[j]
                            break
                        else:
                            j += 1
            i += 1
        
        # Write the updated lines back to the file
        with open(file_path, 'w') as f:
            f.writelines(lines)