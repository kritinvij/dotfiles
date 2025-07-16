#!/usr/bin/env python3

import os
import subprocess
import getpass

NODE_VERSION_TO_INSTALL = "16.15.0"
PYTHON_VERSION_TO_INSTALL = "3.12.4"
TERRAFORM_VERSION_TO_INSTALL = "1.5.5"


class bcolors:
    OKGREEN = '\033[92m'
    BLUE = '\033[94m'
    FAIL = '\033[91m'
    ENDC = '\033[0m'


class UserInteraction:
    def ask_user_connection(self):
        response = input("Are you connected to CORS-CORP wifi in the office or VPN, otherwise (Yes/No): ")
        if response is not None and response.strip().lower().startswith('y'):
            print(bcolors.OKGREEN + f"We can continue with the installations.\n" + bcolors.ENDC)
            return True
        else:
            print(bcolors.FAIL + f"Please connect to the required network." + bcolors.ENDC)
            return False

    def is_username_correct(self):
        try:
            username = getpass.getuser()
            response = input(f"Is your username the same as " + bcolors.BLUE + f"{username}" + bcolors.ENDC + "? (Yes/No): ")
            if response is not None and response.strip().lower().startswith('y'):
                print(bcolors.OKGREEN + f"We can continue with the installations.\n" + bcolors.ENDC)
                return True
            else:
                print(bcolors.FAIL + f"Please contact IT, otherwise your mac might be configured incorrectly." + bcolors.ENDC)
                return False

        except Exception as e:
            print(bcolors.FAIL + f'An error occurred: {e}' + bcolors.ENDC)
            return False


def run_command(command):
    """Runs a command in the shell, prints output, and handles errors."""
    try:
        subprocess.check_output(command, shell=True)
        return 0
    except subprocess.CalledProcessError as e:
        print(bcolors.FAIL + f"Error: An error occurred while running '{command}'.\n{e.output}" + bcolors.ENDC)
        return e.returncode


class Tool:
    def __init__(self, command, name, install_command=None):
        self.command = command
        self.name = name
        self.install_command = install_command if install_command else f'brew install {self.command}'

    def is_installed(self):
        if self.name == 'homebrew':
            try:
                subprocess.check_output(f'which {self.command}', shell=True, stderr=subprocess.DEVNULL)
                print(bcolors.OKGREEN + f'{self.name} is already installed.' + bcolors.ENDC)

                is_brew_analytics_off = subprocess.run(['brew', 'analytics'], capture_output=True, text=True)
                if 'analytics are disabled.' in is_brew_analytics_off.stdout:
                    print(bcolors.OKGREEN + f'brew analytics were already disabled.' + bcolors.ENDC)
                else:
                    subprocess.run(['brew', 'analytics', 'off'])
                    print(bcolors.OKGREEN + f'brew analytics are now disabled.' + bcolors.ENDC)
                return True
            except subprocess.CalledProcessError:
                print(bcolors.FAIL + f"{self.name} is not installed." + bcolors.ENDC)
                return False
        elif self.name == 'nvm':
            try:
                os.environ['NVM_DIR'] = os.path.expanduser('~/.nvm')
                nvm_init_script = os.path.expanduser('~/.nvm/nvm.sh')
                subprocess.check_output(
                    ['bash', '-c', f'source {nvm_init_script} && nvm use --delete-prefix'],
                    stderr=subprocess.STDOUT,
                )
            except Exception as e:
                pass

            try:
                # Load NVM
                os.environ['NVM_DIR'] = os.path.expanduser('~/.nvm')
                nvm_init_script = os.path.expanduser('~/.nvm/nvm.sh')
                subprocess.check_output(
                    ['bash', '-c', f'source {nvm_init_script} && nvm --version'],
                    stderr=subprocess.STDOUT,
                )

                print(bcolors.OKGREEN + 'nvm is already installed.' + bcolors.ENDC)
                return True
            except (FileNotFoundError, subprocess.CalledProcessError):
                print(bcolors.FAIL + "nvm is not installed." + bcolors.ENDC)
                return False
        elif self.name == 'node':
            try:
                os.environ['NVM_DIR'] = os.path.expanduser('~/.nvm')
                nvm_init_script = os.path.expanduser('~/.nvm/nvm.sh')
                subprocess.check_output(
                    ['bash', '-c', f'source {nvm_init_script} && nvm use --delete-prefix'],
                    stderr=subprocess.STDOUT,
                )
            except Exception as e:
                pass

            try:
                installed_version = subprocess.check_output(['node', '-v']).decode('utf-8').strip()
                if installed_version >= f'v{NODE_VERSION_TO_INSTALL}':
                    print(bcolors.OKGREEN + f"    node {installed_version} is installed." + bcolors.ENDC)
                    return True
                else:
                    print(bcolors.FAIL + f"node {NODE_VERSION_TO_INSTALL} is not installed. Current version is {installed_version}." + bcolors.ENDC)
                    return False
            except Exception as e:
                print(bcolors.FAIL + "node is not installed." + bcolors.ENDC)
                return False
        elif self.name == 'pyenv':
            try:
                subprocess.check_output(f'which {self.command}', shell=True, stderr=subprocess.DEVNULL)
                print(bcolors.OKGREEN + f'{self.name} is already installed.' + bcolors.ENDC)
                return True
            except subprocess.CalledProcessError:
                print(bcolors.FAIL + "pyenv is not installed." + bcolors.ENDC)
                return False
        elif self.name == 'python':
            try:
                installed_version = subprocess.check_output(['python', '--version']).decode('utf-8').strip()
                if 'Python {}'.format(PYTHON_VERSION_TO_INSTALL) <= installed_version:
                    print(bcolors.OKGREEN + f"    python {PYTHON_VERSION_TO_INSTALL} is installed and in use." + bcolors.ENDC)
                    return True
                else:
                    result = subprocess.run(['pyenv', 'versions'], stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True)
                    if PYTHON_VERSION_TO_INSTALL in result.stdout:
                        print(bcolors.BLUE + f"Latest python is installed but not in use. Please switch by running `pyenv global {PYTHON_VERSION_TO_INSTALL}`. Make sure you don't have a .python-versions file in the dir or parent dir. Either delete the override file or run `pyenv global {PYTHON_VERSION_TO_INSTALL}`." + bcolors.ENDC)
                        return True
                    else:
                        print(
                            bcolors.FAIL + f"python is not upto date with the correct version: {PYTHON_VERSION_TO_INSTALL}. Current version: {installed_version}" + bcolors.ENDC)
                        return False
            except Exception as e:
                print(bcolors.FAIL + "python is not installed." + bcolors.ENDC)
                return False
        elif self.name == 'tfenv':
            try:
                subprocess.check_output(f'which {self.command}', shell=True, stderr=subprocess.DEVNULL)
                print(bcolors.OKGREEN + f'{self.name} is already installed.' + bcolors.ENDC)
                return True
            except subprocess.CalledProcessError:
                return False
        elif self.name == 'terraform':
            try:
                output = subprocess.check_output(['tfenv', 'list']).decode('utf-8')
                # Extract the version by splitting the output and finding the line with '*'
                # The version used is denoted by '*'
                curr_version = ''
                rqd_version_is_installed = False
                for line in output.split('\n'):
                    if '*' in line:
                        curr_version = line.replace('*', '').strip()
                        if curr_version.startswith(TERRAFORM_VERSION_TO_INSTALL):
                            rqd_version_is_installed = True
                    else:
                        version = line.strip()
                        if version.startswith(TERRAFORM_VERSION_TO_INSTALL):
                            rqd_version_is_installed = True

                curr_version_res = f'Current version is {curr_version}' if curr_version == '' else 'No terraform version is installed'

                if rqd_version_is_installed:
                    print(bcolors.OKGREEN + f"    terraform {TERRAFORM_VERSION_TO_INSTALL} is installed." + bcolors.ENDC)
                    return True
                else:
                    print(
                        bcolors.FAIL + f"terraform {TERRAFORM_VERSION_TO_INSTALL} is not installed. Current version: {curr_version_res}." + bcolors.ENDC)
                    return False
            except Exception as e:
                print(bcolors.FAIL + "tfenv is not installed." + bcolors.ENDC)
                return False
        elif self.name == 'java21':
            try:
                ans = subprocess.check_output(f'java --version', shell=True, stderr=subprocess.DEVNULL)
                if 'openjdk 21' in ans.decode('utf-8'):
                    print(bcolors.OKGREEN + f'{self.name} is already installed.' + bcolors.ENDC)
                    return True
            except subprocess.CalledProcessError:
                return False
        elif self.name == 'git-hooks-go':
            try:
                # Try to get the version of git-hooks-go
                subprocess.check_output(['git-hooks', '-v'], shell=True, stderr=subprocess.DEVNULL)
                print(bcolors.OKGREEN + f'{self.name} is already installed.' + bcolors.ENDC)
                return True
            except subprocess.CalledProcessError:
                print(bcolors.FAIL + f"{self.name} is not installed." + bcolors.ENDC)
                return False
        elif self.name == 'postman':
            # List of common Postman installation directories
            postman_paths = [
                os.path.expanduser('~/Applications/Postman.app/'),  # MacOS
                '/Applications/Postman.app/',  # MacOS
            ]

            for path in postman_paths:
                if os.path.exists(path):
                    print(bcolors.OKGREEN + f'{self.name} is already installed.' + bcolors.ENDC)
                    return True
            return False
        elif self.name == 'awscli':
            try:
                # Run "aws --version" command to check if awscli is installed
                result = subprocess.run(['aws', '--version'], stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True)

                # Amazon's AWS CLI version output usually starts with "aws-cli"
                if 'aws-cli' in result.stdout or 'aws-cli' in result.stderr:
                    print(bcolors.OKGREEN + f'{self.name} is already installed.' + bcolors.ENDC)
                    return True
                else:
                    print(bcolors.FAIL + f"{self.name} is not installed." + bcolors.ENDC)
                    return False
            except FileNotFoundError:
                # If the command is not found, FileNotFoundError is raised
                print(bcolors.FAIL + f"{self.name} is not installed." + bcolors.ENDC)
                return False
            except Exception as e:
                print(bcolors.FAIL + f"{self.name} is not installed." + bcolors.ENDC)
                return False
        else:
            # Default case
            try:
                subprocess.check_output(f'which {self.command}', shell=True, stderr=subprocess.DEVNULL)
                print(bcolors.OKGREEN + f'{self.name} is already installed.' + bcolors.ENDC)
                return True
            except subprocess.CalledProcessError:
                print(bcolors.FAIL + f"{self.name} is not installed." + bcolors.ENDC)
                return False

    def install(self):
        """Installs the tool using provided installation command if not already installed."""
        if not self.is_installed():
            if self.name == 'homebrew':
                try:
                    # Make sure that we create a zshrc file
                    zshrc_path = os.path.expanduser('~/.zshrc')
                    open(zshrc_path, 'a').close()

                    install_homebrew_cmd = '/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install.sh)"'
                    subprocess.run(install_homebrew_cmd, shell=True, check=True, executable="/bin/zsh")

                    print(bcolors.OKGREEN + f"{self.name} is now installed" + bcolors.ENDC)

                    # Add NVM to .zshrc
                    zshrc_path = os.path.expanduser('~/.zshrc')
                    with open(zshrc_path, 'a') as file:
                        # Add Homebrew to PATH
                        file.write('export PATH="$HOME/bin:$PATH"')
                        file.write('export PATH="/usr/local/sbin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin:$PATH"')
                        file.write('export PATH="/opt/homebrew/bin:/opt/homebrew/sbin:$PATH"')

                    os.environ["PATH"] = os.path.expanduser("~/bin") + os.pathsep + os.environ["PATH"]
                    os.environ["PATH"] = "/usr/local/sbin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin" + os.pathsep + os.environ["PATH"]
                    os.environ["PATH"] = "/opt/homebrew/bin:/opt/homebrew/sbin" + os.pathsep + os.environ["PATH"]
                    run_command('which brew')

                except Exception as e:
                    pass

                try:
                    subprocess.run(['brew', 'analytics', 'off'])
                    print(bcolors.OKGREEN + f'brew analytics are now disabled.' + bcolors.ENDC)
                except Exception as e:
                    pass
            elif self.name == 'nvm':
                command = 'curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.1/install.sh | bash'
                run_command(command)
                print(bcolors.OKGREEN + f'{self.name} is now installed' + bcolors.ENDC)

                # Load NVM
                os.environ['NVM_DIR'] = os.path.expanduser('~/.nvm')
                nvm_init_script = os.path.expanduser('~/.nvm/nvm.sh')
                subprocess.check_output(
                    ['bash', '-c', f'source {nvm_init_script} && nvm --version'],
                    stderr=subprocess.STDOUT,
                )

                commands = [
                    r'export NVM_DIR="$HOME/.nvm"',
                    r'[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"',
                    r'[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"',
                ]

                # Add NVM to .zshrc
                zshrc_path = os.path.expanduser('~/.zshrc')
                with open(zshrc_path, 'a') as f:
                    for line in commands:
                        f.write(line + '\n')
            elif self.name == 'node':
                try:
                    os.environ['NVM_DIR'] = os.path.expanduser('~/.nvm')
                    nvm_init_script = os.path.expanduser('~/.nvm/nvm.sh')
                    subprocess.check_output(
                        ['bash', '-c', f'source {nvm_init_script} && nvm use --delete-prefix'],
                        stderr=subprocess.STDOUT,
                    )
                except Exception as e:
                    pass

                try:
                    installed_version = subprocess.check_output(['node', '-v']).decode('utf-8').strip()
                    if installed_version >= f'v{NODE_VERSION_TO_INSTALL}':
                        print(bcolors.OKGREEN + f"  node {installed_version} is installed." + bcolors.ENDC)
                        return True
                except Exception as e:
                    # Load NVM
                    os.environ['NVM_DIR'] = os.path.expanduser('~/.nvm')
                    nvm_init_script = os.path.expanduser('~/.nvm/nvm.sh')

                    # Load NVM, and install Node.js v16.15.0
                    subprocess.check_output(
                        ['bash', '-c', f'source {nvm_init_script} && nvm --version'],
                        stderr=subprocess.STDOUT,
                    )

                    subprocess.check_output(
                        ['bash', '-c', f'source {nvm_init_script} && nvm install {NODE_VERSION_TO_INSTALL}'],
                        stderr=subprocess.STDOUT,
                    )

                    try:
                        subprocess.check_output(
                            ['bash', '-c', f'source {nvm_init_script} && nvm use --delete-prefix'],
                            stderr=subprocess.STDOUT,
                        )
                    except Exception as e:
                        pass

                    subprocess.check_output(
                        ['bash', '-c',
                         f'source {nvm_init_script} && nvm alias default {NODE_VERSION_TO_INSTALL}'],
                        stderr=subprocess.STDOUT,
                    )
                    print(bcolors.OKGREEN + f'{self.name} is now installed' + bcolors.ENDC)
            elif self.name == 'pyenv':
                run_command(self.install_command)

                # Load pyenv into current zsh shell
                os.environ['PYENV_ROOT'] = os.path.expanduser('~/.pyenv')
                os.environ['PATH'] = f'{os.environ["PYENV_ROOT"]}/bin:{os.environ["PATH"]}'
                subprocess.run(['eval "$(pyenv init)"'], shell=True)

                lines = [
                    'export PYENV_ROOT="$HOME/.pyenv"',
                    '[[ -d $PYENV_ROOT/bin ]] && export PATH="$PYENV_ROOT/bin:$PATH"',
                    'eval "$(pyenv init -)"'
                ]

                zshrc_path = os.path.expanduser('~/.zshrc')
                with open(zshrc_path, 'a') as file:
                    for line in lines:
                        file.write(line + '\n')
                print(bcolors.OKGREEN + f'{self.name} is now installed' + bcolors.ENDC)
            elif self.name == 'python':
                run_command(f'pyenv install {PYTHON_VERSION_TO_INSTALL}')
                run_command(f'pyenv global {PYTHON_VERSION_TO_INSTALL}')
                print(bcolors.OKGREEN + f'{self.name} is now installed' + bcolors.ENDC)
            elif self.name == 'tfenv':
                run_command(self.install_command)
                print(bcolors.OKGREEN + f'{self.name} is now installed' + bcolors.ENDC)
            elif self.name == 'terraform':
                run_command(f'tfenv install {TERRAFORM_VERSION_TO_INSTALL}')
                print(bcolors.OKGREEN + f'{self.name} is now installed' + bcolors.ENDC)
            elif self.name == 'java21':
                commands = [
                    'mkdir -p /Library/Java/JavaVirtualMachines && cd /Library/Java/JavaVirtualMachines/ && sudo curl https://cdn.azul.com/zulu/bin/zulu21.32.17-ca-jdk21.0.2-macosx_aarch64.tar.gz -O && sudo tar -xzf zulu21.32.17-ca-jdk21.0.2-macosx_aarch64.tar.gz && sudo mv zulu21.32.17-ca-jdk21.0.2-macosx_aarch64/zulu-21.jdk . && sudo rm zulu21.32.17-ca-jdk21.0.2-macosx_aarch64.tar.gz && sudo rm -rf zulu21.32.17-ca-jdk21.0.2-macosx_aarch64 && cd ~'
                ]

                for command in commands:
                    run_command(command)
                print(bcolors.OKGREEN + f'{self.name} is now installed' + bcolors.ENDC)
            elif self.name == 'yarn':
                # Load NVM
                os.environ['NVM_DIR'] = os.path.expanduser('~/.nvm')
                nvm_init_script = os.path.expanduser('~/.nvm/nvm.sh')
                subprocess.check_output(
                    ['bash', '-c', f'source {nvm_init_script} && curl -o- -L https://yarnpkg.com/install.sh | bash -s -- --version "1.10.1"'],
                    stderr=subprocess.STDOUT,
                )

                run_command(self.install_command)
                print(bcolors.OKGREEN + f'{self.name} is now installed' + bcolors.ENDC)
                lines = [
                    'export PATH="$HOME/.yarn/bin:$HOME/.config/yarn/global/node_modules/.bin:$PATH"',
                ]
                zshrc_path = os.path.expanduser('~/.zshrc')
                with open(zshrc_path, 'a') as file:
                    for line in lines:
                        file.write(line + "\n")
            else:
                res = run_command(self.install_command)
                print(bcolors.OKGREEN + f'{self.name} is now installed' + bcolors.ENDC)
                return res


if __name__ == '__main__':
    user_interaction = UserInteraction()
    user_conn_res = user_interaction.ask_user_connection()
    if not user_conn_res:
        exit(1)

    if not user_interaction.is_username_correct():
        exit(1)

    tools = [
        Tool('brew', 'homebrew'),
        Tool('nvm', 'nvm'),
        Tool('node', 'node'),
        Tool('pyenv', 'pyenv'),
        Tool('python', 'python'),
        Tool('tfenv', 'tfenv'),
        Tool('terraform', 'terraform'),
        Tool('java21', 'java21'),
        Tool('yarn', 'yarn'),
        Tool('git', 'git'),
        Tool('gh', 'github-cli'),
        Tool('git-hooks-go', 'git-hooks-go', 'brew install git-hooks-go --quiet'),
        Tool('jq', 'jq'),
        Tool('postman', 'postman'),
        Tool('docker', 'docker', 'brew install --cask docker'),
        Tool('awscli', 'awscli'),
        Tool('diff-so-fancy', 'diff-so-fancy'),
        Tool('lsd', 'lsd'),
        Tool('bat', 'bat'),
        Tool('fd', 'fd'),
        Tool('ag', 'silver-searcher'),
        Tool('autoupdate, 'autoupdate', 'brew tap domt4/autoupdate'),
    ]

    for tool in tools:
        tool.install()

    print("\nInstallation process complete! Remember to " + bcolors.BLUE + "restart your terminal and/or run 'source ~/.zshrc'." + bcolors.ENDC)
    exit(0)
