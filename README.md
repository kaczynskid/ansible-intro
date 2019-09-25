 - what is Ansible?
    ```text
    Ansible is a radically simple IT automation engine that automates cloud provisioning,
    configuration management, application deployment, intra-service orchestration,
    and many other IT needs.
    ```

 - install Ansible
    ```shell script
    pip install ansible
    ```

 - configure Ansible
    ```shell script
    cat ansible.cfg
    ```

 - ad-hoc commands
   ```shell script
   ansible 127.0.0.1 -a "pwd"
   ```

 - create local inventory
    ```text
    localhost	ansible_connection=local
    ```
 
 - first playbook
    ```yaml
    # site.yml
    - hosts: all
      tasks:
        - git:
            repo: "git@github.com:kaczynskid/ansible-test.git"
            dest: "{{system_base_dir}}/ansible-test"
    ```

 - define groups in inventory group_vars
    ```yaml
    # group_vars/all/vars.yml
    system_base_dir: "/tmp/app"
    ```

 - run the playbook on inventory
    ```shell script
    ansible-playbook -i machine.inv site.yml
    ```

 - docker machine
    ```shell script
    docker-machine ls
    docker-machine create --driver virtualbox default
    eval $(docker-machine env default)
    ssh -i $DOCKER_CERT_PATH/id_rsa docker@`docker-machine ip $DOCKER_MACHINE_NAME`
    ```

 - configure machine inventory
    ```yaml
    # machine.inv
    machine
    ```

 - and machine host_vars
    ```yaml
    # host_vars/machine/vars.yml
    ansible_host: "{{ lookup('pipe', 'docker-machine ip $DOCKER_MACHINE_NAME') }}"
    ansible_user: "{{ lookup('pipe', './getdockeruser.sh') }}"
    ansible_ssh_private_key_file: "{{ lookup('env', 'DOCKER_CERT_PATH' ) }}/id_rsa"
    ansible_python_interpreter: "/usr/local/bin/python"
    ```

 - install python
    ```yaml
    # host_vars/machine/main.yml
    tce_load_python: "{{ lookup('pipe', './checkifvirtualbox.sh') }}"    
    ```
    ```yaml
    # setup.yml
    - hosts: all
      gather_facts: False
      tasks:
        - name: install python
          raw: "tce-load -w -i python"
          when: tce_load_python | default(False)
    ```

 - roles
    ```yaml
    # roles/git-host/defaults
    # roles/git-host/files
    # roles/git-host/handlers
    # roles/git-host/meta
    # roles/git-host/tasks
    # roles/git-host/templates
    # roles/git-host/vars
    ```
    ```yaml
    - hosts: all
      roles:
        - git-host
    ```

 - install pip & git depending on target package manager 
    ```yaml
    - include: dependencies_apt.yml
      when: ansible_pkg_mgr == "apt"
    
    - include: dependencies_yum.yml
      when: ansible_pkg_mgr == "yum"
    
    - include: dependencies_unknown.yml
      when: ansible_pkg_mgr == "unknown"
    ```

 - update pip
    ```yaml
    - name: locate pip executable
      command: which pip
      changed_when: False
      register: pip_path
    
    - name: update pip
      pip:
        name: pip
        state: latest
        executable: "{{ pip_path.stdout_lines[0] | trim }}"
      become: yes
      become_method: sudo
    ```

 - install extra python modules
    ```yaml
    - name: locate updated pip executable
      command: which pip
      changed_when: False
      register: new_pip_path
    
    - name: install python libraries if missing
      pip:
        name: "{{ item }}"
        state: latest
        executable: "{{ new_pip_path.stdout_lines[0] | trim }}"
      become: yes
      become_method: sudo
      with_items:
        - httplib2
        - docker-py
        - kazoo
        - botocore
        - boto
        - boto3
    ```

 - create local and remote directories
    ```yaml
    - name: make sure local directory exists
      local_action:
        module: file
        path: "{{ system_local_dir }}"
        state: directory
        mode: 0777
    
    - name: make sure base directory exist
      file:
        path: "{{ system_base_dir }}"
        state: directory
        mode: 0777
        owner: "{{ system_user_name }}"
        group: "{{ system_user_name }}"
      become: yes
      become_method: sudo
    ```

 - generate new ssh key
    ```shell script
    ssh-keygen -f .id_rsa -C auto@acme.com
    ```
    ```yaml
    system_ssh_key: "-----BEGIN RSA PRIVATE KEY-----..."
    system_ssh_key_pub: "ssh-rsa AAAA..."
    ```

 - Ansible Vault password file
    ```shell script
    cat .vault_pass.txt 
    siicret
    ```

 - encrypt ssh keys
    ```shell script
    ansible-vault encrypt roles/git-host/defaults/main.yml --vault-password-file ./.vault_pass.txt
    ansible-vault decrypt roles/git-host/defaults/main.yml --vault-password-file ./.vault_pass.txt
    ```

 - install ssh keys
    ```yaml
    - name: check if ssh key exists
      stat:
        path: "~/.ssh/id_rsa"
      register: docker_host_ssh_status
    
    - name: install ssh key
      template:
        src: "id_rsa.j2"
        dest: "~/.ssh/id_rsa"
        mode: 0600
      when: not docker_host_ssh_status.stat.exists
    
    - name: install ssh public key
      template:
        src: "id_rsa.pub.j2"
        dest: "~/.ssh/id_rsa.pub"
        mode: 0600
      when: not docker_host_ssh_status.stat.exists
    ``` 

 - configure git
    ```yaml
    - name: check if git config exists
      stat:
        path: "~/.gitconfig"
      register: docker_host_git_status
    
    - name: install git config
      template:
        src: "gitconfig.j2"
        dest: "~/.gitconfig"
        mode: 0600
      when: not docker_host_git_status.stat.exists
    
    - name: add github host key to known_hosts
      shell: "ssh-keygen -R {{ item }}; ssh-keyscan -H {{ item }} >> ~/.ssh/known_hosts"
      with_items:
        - "github.com"
    ```
