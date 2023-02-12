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
        for i, line in enumerate(lines):
            match = task_pattern.match(line)
            if match:
                task_name = match.group(1)
                # Check if the next line is a task definition
                if lines[i+1].strip().startswith('ansible.builtin.iptables:'):
                    lines[i+1] = lines[i+1].rstrip() + '\n    comment: "{}"\n'.format(task_name)
        
        # Write the updated lines back to the file
        with open(file_path, 'w') as f:
            f.writelines(lines)