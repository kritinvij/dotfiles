#!/usr/bin/env python3

import argparse
import os
import re
import sys
import subprocess
import getpass
from typing import Tuple

try:
    from tqdm import tqdm
except ImportError:
    print("Installing tqdm for progress display...")  # Can't use tqdm.write yet
    subprocess.check_call([sys.executable, '-m', 'pip', 'install', 'tqdm', '-q'])
    from tqdm import tqdm


def log(message: str, end: str = '\n'):
    """Print a message using tqdm.write to avoid interfering with progress bars."""
    tqdm.write(message, end=end)

# Global dry-run flag
DRY_RUN = False

# =============================================================================
# Version Configuration - All tool versions consolidated here
# =============================================================================
NODE_VERSION_TO_INSTALL = "20.12.2"
PYTHON_VERSION_TO_INSTALL = "3.13.2"
TERRAFORM_VERSION_TO_INSTALL = "1.5.5"
NVM_VERSION_TO_INSTALL = "0.39.1"
YARN_VERSION_TO_INSTALL = "1.10.1"
JAVA_VERSION = "21"
ZULU_JDK_VERSION = "21.32.17"
ZULU_JDK_RELEASE = "21.0.2"


class Colors:
    OKGREEN = '\033[92m'
    BLUE = '\033[94m'
    FAIL = '\033[91m'
    ENDC = '\033[0m'
    BOLD = '\033[1m'
    DIM = '\033[2m'


# =============================================================================
# Helper Functions
# =============================================================================

def compare_versions(version1: str, version2: str) -> int:
    """
    Compare two semantic versions.
    Returns: -1 if version1 < version2, 0 if equal, 1 if version1 > version2
    """
    # Strip leading 'v' or 'Python ' prefix if present
    v1 = version1.lstrip('v').replace('Python ', '')
    v2 = version2.lstrip('v').replace('Python ', '')
    
    # Split into parts and convert to integers
    v1_parts = [int(x) for x in v1.split('.')]
    v2_parts = [int(x) for x in v2.split('.')]
    
    # Pad shorter version with zeros
    max_len = max(len(v1_parts), len(v2_parts))
    v1_parts.extend([0] * (max_len - len(v1_parts)))
    v2_parts.extend([0] * (max_len - len(v2_parts)))
    
    for p1, p2 in zip(v1_parts, v2_parts):
        if p1 < p2:
            return -1
        elif p1 > p2:
            return 1
    return 0


def ensure_nvm_loaded() -> Tuple[str, str]:
    """
    Ensure NVM environment is set up and return NVM_DIR and init script path.
    Attempts to run 'nvm use --delete-prefix' to fix any prefix issues.
    """
    nvm_dir = os.path.expanduser('~/.nvm')
    nvm_init_script = os.path.join(nvm_dir, 'nvm.sh')
    os.environ['NVM_DIR'] = nvm_dir
    
    # Try to fix prefix issues silently
    try:
        subprocess.check_output(
            ['bash', '-c', f'source {nvm_init_script} && nvm use --delete-prefix'],
            stderr=subprocess.STDOUT,
        )
    except Exception:
        pass  # Non-critical, continue anyway
    
    return nvm_dir, nvm_init_script


def append_to_zshrc_if_missing(content: str, marker: str) -> bool:
    """
    Append content to ~/.zshrc only if the marker string is not already present.
    Returns True if content was added, False if it was already present.
    """
    zshrc_path = os.path.expanduser('~/.zshrc')
    
    # Ensure file exists
    if not os.path.exists(zshrc_path):
        open(zshrc_path, 'a').close()
    
    # Check if marker already exists
    with open(zshrc_path, 'r') as f:
        if marker in f.read():
            return False  # Already present
    
    # Append content
    with open(zshrc_path, 'a') as f:
        f.write(content)
    return True


class UserInteraction:
    def ask_user_connection(self):
        response = input("Are you connected to CORS-CORP wifi in the office or VPN, otherwise (Yes/No): ")
        if response and response.strip().lower().startswith('y'):
            log(Colors.OKGREEN + "We can continue with the installations.\n" + Colors.ENDC)
            return True
        else:
            log(Colors.FAIL + "Please connect to the required network." + Colors.ENDC)
            return False

    def is_username_correct(self):
        try:
            username = getpass.getuser()
            response = input("Is your username the same as " + Colors.BLUE + username + Colors.ENDC + "? (Yes/No): ")
            if response and response.strip().lower().startswith('y'):
                log(Colors.OKGREEN + "We can continue with the installations.\n" + Colors.ENDC)
                return True
            else:
                log(Colors.FAIL + "Please contact IT, otherwise your mac might be configured incorrectly." + Colors.ENDC)
                return False

        except Exception as e:
            log(Colors.FAIL + f'An error occurred: {e}' + Colors.ENDC)
            return False


def run_command(command, skip_in_dry_run=True):
    """Runs a command in the shell, prints output, and handles errors.
    
    Args:
        command: The shell command to run
        skip_in_dry_run: If True, skip execution in dry-run mode. If False, always execute.
    """
    if DRY_RUN and skip_in_dry_run:
        log(f"{Colors.DIM}  [dry-run] Would run: {command}{Colors.ENDC}")
        return 0
    try:
        subprocess.check_output(command, shell=True)
        return 0
    except subprocess.CalledProcessError as e:
        log(Colors.FAIL + f"Error: An error occurred while running '{command}'.\n{e.output}" + Colors.ENDC)
        return e.returncode


class Tool:
    def __init__(self, command, name, install_command=None):
        self.command = command
        self.name = name
        self.install_command = install_command if install_command else f'brew install {self.command}'

    def is_installed(self) -> bool:
        """Check if the tool is already installed. Returns True if installed, False otherwise."""
        if self.name == 'homebrew':
            try:
                subprocess.check_output(f'which {self.command}', shell=True, stderr=subprocess.DEVNULL)
                
                # Check and disable analytics
                is_brew_analytics_off = subprocess.run(['brew', 'analytics'], capture_output=True, text=True)
                if 'analytics are disabled.' in is_brew_analytics_off.stdout:
                    analytics_status = "brew analytics were already disabled."
                else:
                    subprocess.run(['brew', 'analytics', 'off'])
                    analytics_status = "brew analytics are now disabled."
                
                log(Colors.OKGREEN + f'{self.name} is already installed ({analytics_status}).' + Colors.ENDC)
                return True
            except subprocess.CalledProcessError:
                log(Colors.FAIL + f"{self.name} is not installed." + Colors.ENDC)
                return False
        elif self.name == 'nvm':
            _, nvm_init_script = ensure_nvm_loaded()

            try:
                subprocess.check_output(
                    ['bash', '-c', f'source {nvm_init_script} && nvm --version'],
                    stderr=subprocess.STDOUT,
                )
                log(Colors.OKGREEN + 'nvm is already installed.' + Colors.ENDC)
                return True
            except (FileNotFoundError, subprocess.CalledProcessError):
                log(Colors.FAIL + "nvm is not installed." + Colors.ENDC)
                return False
        elif self.name == 'node':
            _, nvm_init_script = ensure_nvm_loaded()

            try:
                # Use nvm to check installed versions directly (more reliable than node -v)
                result = subprocess.run(
                    ['bash', '-c', f'source {nvm_init_script} && nvm ls'],
                    capture_output=True,
                    text=True
                )
                if result.returncode != 0:
                    log(Colors.FAIL + "nvm is not available to check node versions." + Colors.ENDC)
                    return False
                
                # Check if required version (or higher) is installed
                # nvm ls output shows installed versions, current one marked with ->
                for line in result.stdout.split('\n'):
                    # Strip ANSI color codes and whitespace
                    clean_line = line.strip()
                    if not clean_line or 'system' in clean_line or 'N/A' in clean_line:
                        continue
                    
                    # Extract version number (handle formats like "v16.15.0", "->     v16.15.0", etc.)
                    version_match = re.search(r'v(\d+\.\d+\.\d+)', clean_line)
                    if version_match:
                        installed_version = version_match.group(1)
                        if compare_versions(installed_version, NODE_VERSION_TO_INSTALL) >= 0:
                            is_current = '->' in clean_line or '*' in clean_line
                            if is_current:
                                log(Colors.OKGREEN + f"    node v{installed_version} is installed and active." + Colors.ENDC)
                            else:
                                log(Colors.OKGREEN + f"    node v{installed_version} is installed." + Colors.ENDC)
                            return True
                
                log(Colors.FAIL + f"node {NODE_VERSION_TO_INSTALL} or higher is not installed via nvm." + Colors.ENDC)
                return False
            except Exception:
                log(Colors.FAIL + "node is not installed." + Colors.ENDC)
                return False
        elif self.name == 'pyenv':
            try:
                subprocess.check_output(f'which {self.command}', shell=True, stderr=subprocess.DEVNULL)
                log(Colors.OKGREEN + f'{self.name} is already installed.' + Colors.ENDC)
                return True
            except subprocess.CalledProcessError:
                log(Colors.FAIL + "pyenv is not installed." + Colors.ENDC)
                return False
        elif self.name == 'python':
            try:
                # Use pyenv to check installed versions directly (more reliable than python --version)
                result = subprocess.run(['pyenv', 'versions'], stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True)
                if result.returncode != 0:
                    log(Colors.FAIL + "pyenv is not available to check python versions." + Colors.ENDC)
                    return False
                
                # Check if required version is installed via pyenv
                if PYTHON_VERSION_TO_INSTALL in result.stdout:
                    # Check if it's the currently active version (marked with *)
                    for line in result.stdout.split('\n'):
                        if PYTHON_VERSION_TO_INSTALL in line and '*' in line:
                            log(Colors.OKGREEN + f"    python {PYTHON_VERSION_TO_INSTALL} is installed and in use." + Colors.ENDC)
                            return True
                    # Version installed but not active
                    log(Colors.BLUE + f"python {PYTHON_VERSION_TO_INSTALL} is installed but not in use. Please switch by running `pyenv global {PYTHON_VERSION_TO_INSTALL}`. Make sure you don't have a .python-version file in the dir or parent dir." + Colors.ENDC)
                    return True
                else:
                    log(Colors.FAIL + f"python {PYTHON_VERSION_TO_INSTALL} is not installed via pyenv." + Colors.ENDC)
                    return False
            except Exception:
                log(Colors.FAIL + "python is not installed." + Colors.ENDC)
                return False
        elif self.name == 'tfenv':
            try:
                subprocess.check_output(f'which {self.command}', shell=True, stderr=subprocess.DEVNULL)
                log(Colors.OKGREEN + f'{self.name} is already installed.' + Colors.ENDC)
                return True
            except subprocess.CalledProcessError:
                log(Colors.FAIL + f"{self.name} is not installed." + Colors.ENDC)
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

                curr_version_res = f'Current version is {curr_version}' if curr_version != '' else 'No terraform version is installed'

                if rqd_version_is_installed:
                    log(Colors.OKGREEN + f"    terraform {TERRAFORM_VERSION_TO_INSTALL} is installed." + Colors.ENDC)
                    return True
                else:
                    log(Colors.FAIL + f"terraform {TERRAFORM_VERSION_TO_INSTALL} is not installed. Current version: {curr_version_res}." + Colors.ENDC)
                    return False
            except Exception:
                log(Colors.FAIL + "tfenv is not installed." + Colors.ENDC)
                return False
        elif self.name == 'java21':
            try:
                ans = subprocess.check_output('java --version', shell=True, stderr=subprocess.DEVNULL)
                if f'openjdk {JAVA_VERSION}' in ans.decode('utf-8'):
                    log(Colors.OKGREEN + f'{self.name} is already installed.' + Colors.ENDC)
                    return True
                else:
                    log(Colors.FAIL + f"{self.name} is not installed." + Colors.ENDC)
                    return False
            except subprocess.CalledProcessError:
                log(Colors.FAIL + f"{self.name} is not installed." + Colors.ENDC)
                return False
        elif self.name == 'git-hooks-go':
            try:
                # Try to get the version of git-hooks-go
                subprocess.check_output(['git-hooks', '-v'], shell=True, stderr=subprocess.DEVNULL)
                log(Colors.OKGREEN + f'{self.name} is already installed.' + Colors.ENDC)
                return True
            except subprocess.CalledProcessError:
                log(Colors.FAIL + f"{self.name} is not installed." + Colors.ENDC)
                return False
        elif self.name == 'postman':
            # List of common Postman installation directories
            postman_paths = [
                os.path.expanduser('~/Applications/Postman.app/'),  # MacOS
                '/Applications/Postman.app/',  # MacOS
            ]

            for path in postman_paths:
                if os.path.exists(path):
                    log(Colors.OKGREEN + f'{self.name} is already installed.' + Colors.ENDC)
                    return True
            log(Colors.FAIL + f"{self.name} is not installed." + Colors.ENDC)
            return False
        elif self.name == 'awscli':
            try:
                # Run "aws --version" command to check if awscli is installed
                result = subprocess.run(['aws', '--version'], stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True)

                # Amazon's AWS CLI version output usually starts with "aws-cli"
                if 'aws-cli' in result.stdout or 'aws-cli' in result.stderr:
                    log(Colors.OKGREEN + f'{self.name} is already installed.' + Colors.ENDC)
                    return True
                else:
                    log(Colors.FAIL + f"{self.name} is not installed." + Colors.ENDC)
                    return False
            except FileNotFoundError:
                # If the command is not found, FileNotFoundError is raised
                log(Colors.FAIL + f"{self.name} is not installed." + Colors.ENDC)
                return False
            except Exception:
                log(Colors.FAIL + f"{self.name} is not installed." + Colors.ENDC)
                return False
        else:
            # Default case
            try:
                subprocess.check_output(f'which {self.command}', shell=True, stderr=subprocess.DEVNULL)
                log(Colors.OKGREEN + f'{self.name} is already installed.' + Colors.ENDC)
                return True
            except subprocess.CalledProcessError:
                log(Colors.FAIL + f"{self.name} is not installed." + Colors.ENDC)
                return False

    def install(self) -> bool:
        """
        Installs the tool using provided installation command if not already installed.
        Returns True if installed successfully or already installed, False otherwise.
        """
        if self.is_installed():
            return True  # Already installed, nothing to do
        
        # Tool is not installed, proceed with installation
        if self.name == 'homebrew':
            try:
                # Make sure that we create a zshrc file
                zshrc_path = os.path.expanduser('~/.zshrc')
                if not os.path.exists(zshrc_path):
                    open(zshrc_path, 'a').close()

                install_homebrew_cmd = '/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install.sh)"'
                subprocess.run(install_homebrew_cmd, shell=True, check=True, executable="/bin/zsh")

                # Add consolidated PATH to .zshrc (idempotent)
                path_content = '''
########################## Paths ##########################
# Consolidated PATH - order matters (earlier = higher priority)
export PATH="$HOME/bin:$HOME/.local/bin:/opt/homebrew/bin:/opt/homebrew/sbin:$HOME/.yarn/bin:$HOME/.config/yarn/global/node_modules/.bin:/usr/local/sbin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin:$PATH"
'''
                append_to_zshrc_if_missing(path_content, '########################## Paths ##########################')

                os.environ["PATH"] = os.path.expanduser("~/bin") + os.pathsep + os.environ["PATH"]
                os.environ["PATH"] = "/usr/local/sbin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin" + os.pathsep + os.environ["PATH"]
                os.environ["PATH"] = "/opt/homebrew/bin:/opt/homebrew/sbin" + os.pathsep + os.environ["PATH"]
                run_command('which brew')

            except Exception:
                pass

            try:
                subprocess.run(['brew', 'analytics', 'off'])
            except Exception:
                pass
            
            log(Colors.OKGREEN + f'{self.name} is now installed (analytics disabled).' + Colors.ENDC)
            return True
        elif self.name == 'nvm':
            command = f'curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v{NVM_VERSION_TO_INSTALL}/install.sh | bash'
            run_command(command)
            log(Colors.OKGREEN + f'{self.name} is now installed' + Colors.ENDC)

            # Load NVM
            _, nvm_init_script = ensure_nvm_loaded()
            subprocess.check_output(
                ['bash', '-c', f'source {nvm_init_script} && nvm --version'],
                stderr=subprocess.STDOUT,
            )

            # Add NVM lazy-load to .zshrc (idempotent)
            # Note: We add nvm's default node to PATH so scripts using #!/usr/bin/env node work
            nvm_zshrc_content = '''
# nvm
export NVM_DIR="$HOME/.nvm"

# Add default node version to PATH for non-interactive scripts (e.g., git hooks)
# This ensures node/npm are available without requiring lazy-load initialization
if [ -d "$NVM_DIR/versions/node" ]; then
  DEFAULT_NODE_PATH="$NVM_DIR/versions/node/$(ls -1 $NVM_DIR/versions/node | sort -V | tail -1)/bin"
  export PATH="$DEFAULT_NODE_PATH:$PATH"
fi

# Lazy-load nvm - only initialize when actually used (for interactive shell)
if [ -s "$NVM_DIR/nvm.sh" ]; then
  _load_nvm() {
    unset -f nvm node npm npx yarn
    source "$NVM_DIR/nvm.sh"
    [ -s "$NVM_DIR/bash_completion" ] && source "$NVM_DIR/bash_completion"
  }

  # Create wrapper functions that trigger nvm initialization
  nvm() { _load_nvm && nvm "$@"; }
  node() { _load_nvm && node "$@"; }
  npm() { _load_nvm && npm "$@"; }
  npx() { _load_nvm && npx "$@"; }
  yarn() { _load_nvm && yarn "$@"; }
fi
'''
            append_to_zshrc_if_missing(nvm_zshrc_content, '# nvm')
            return True
        elif self.name == 'node':
            _, nvm_init_script = ensure_nvm_loaded()

            try:
                installed_version = subprocess.check_output(['node', '-v']).decode('utf-8').strip()
                if compare_versions(installed_version, NODE_VERSION_TO_INSTALL) >= 0:
                    log(Colors.OKGREEN + f"  node {installed_version} is installed." + Colors.ENDC)
                    return True
            except Exception:
                pass
            
            # Install node via nvm
            subprocess.check_output(
                ['bash', '-c', f'source {nvm_init_script} && nvm --version'],
                stderr=subprocess.STDOUT,
            )

            subprocess.check_output(
                ['bash', '-c', f'source {nvm_init_script} && nvm install {NODE_VERSION_TO_INSTALL}'],
                stderr=subprocess.STDOUT,
            )

            ensure_nvm_loaded()  # Fix any prefix issues after install

            subprocess.check_output(
                ['bash', '-c',
                 f'source {nvm_init_script} && nvm alias default {NODE_VERSION_TO_INSTALL}'],
                stderr=subprocess.STDOUT,
            )
            log(Colors.OKGREEN + f'{self.name} is now installed' + Colors.ENDC)
            return True
        elif self.name == 'pyenv':
            run_command(self.install_command)

            # Load pyenv into current zsh shell
            os.environ['PYENV_ROOT'] = os.path.expanduser('~/.pyenv')
            os.environ['PATH'] = f'{os.environ["PYENV_ROOT"]}/bin:{os.environ["PATH"]}'
            subprocess.run(['eval "$(pyenv init)"'], shell=True)

            # Add pyenv lazy-load to .zshrc (idempotent)
            pyenv_zshrc_content = '''
# pyenv
# Lazy-load pyenv - only initialize when actually used
export PYENV_ROOT="$HOME/.pyenv"
export PATH="$PYENV_ROOT/bin:$PATH"

if command -v pyenv &>/dev/null; then
  _load_pyenv() {
    unset -f pyenv python python3 pip pip3
    eval "$(pyenv init -)"
  }
  pyenv() { _load_pyenv && pyenv "$@"; }
  python() { _load_pyenv && python "$@"; }
  python3() { _load_pyenv && python3 "$@"; }
  pip() { _load_pyenv && pip "$@"; }
  pip3() { _load_pyenv && pip3 "$@"; }
fi
'''
            append_to_zshrc_if_missing(pyenv_zshrc_content, '# pyenv')
            log(Colors.OKGREEN + f'{self.name} is now installed' + Colors.ENDC)
            return True
        elif self.name == 'python':
            # Check if version already exists before trying to install
            result = subprocess.run(['pyenv', 'versions'], stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True)
            version_exists = PYTHON_VERSION_TO_INSTALL in result.stdout
            
            if not version_exists:
                # Install the version (user may be prompted if version exists)
                install_result = subprocess.run(
                    f'pyenv install {PYTHON_VERSION_TO_INSTALL}',
                    shell=True,
                    capture_output=True,
                    text=True
                )
                if install_result.returncode != 0:
                    # Check if it's because version already exists or user cancelled
                    if 'already exists' in install_result.stderr:
                        log(Colors.BLUE + f"python {PYTHON_VERSION_TO_INSTALL} already exists." + Colors.ENDC)
                    else:
                        # User likely cancelled or other error - don't print error, just skip
                        log(Colors.BLUE + f"Skipping python {PYTHON_VERSION_TO_INSTALL} installation." + Colors.ENDC)
                        return False
            
            # Set as global version
            run_command(f'pyenv global {PYTHON_VERSION_TO_INSTALL}')
            log(Colors.OKGREEN + f'{self.name} is now installed' + Colors.ENDC)
            return True
        elif self.name == 'tfenv':
            run_command(self.install_command)
            
            # Add tfenv lazy-load to .zshrc (idempotent)
            tfenv_zshrc_content = '''
# tfenv
# Lazy-load tfenv - only initialize when actually used
export PATH="$HOME/.tfenv/bin:$PATH"

if [ -d "$HOME/.tfenv" ]; then
  _load_tfenv() {
    unset -f tfenv terraform
  }
  tfenv() { _load_tfenv && command tfenv "$@"; }
  terraform() { _load_tfenv && command terraform "$@"; }
fi
'''
            append_to_zshrc_if_missing(tfenv_zshrc_content, '# tfenv')
            log(Colors.OKGREEN + f'{self.name} is now installed' + Colors.ENDC)
            return True
        elif self.name == 'terraform':
            run_command(f'tfenv install {TERRAFORM_VERSION_TO_INSTALL}')
            log(Colors.OKGREEN + f'{self.name} is now installed' + Colors.ENDC)
            return True
        elif self.name == 'java21':
            # Build the Zulu JDK download URL from version constants
            zulu_archive = f'zulu{ZULU_JDK_VERSION}-ca-jdk{ZULU_JDK_RELEASE}-macosx_aarch64'
            commands = [
                f'mkdir -p /Library/Java/JavaVirtualMachines && cd /Library/Java/JavaVirtualMachines/ && sudo curl https://cdn.azul.com/zulu/bin/{zulu_archive}.tar.gz -O && sudo tar -xzf {zulu_archive}.tar.gz && sudo mv {zulu_archive}/zulu-{JAVA_VERSION}.jdk . && sudo rm {zulu_archive}.tar.gz && sudo rm -rf {zulu_archive} && cd ~'
            ]

            for command in commands:
                run_command(command)
            log(Colors.OKGREEN + f'{self.name} is now installed' + Colors.ENDC)
            return True
        elif self.name == 'yarn':
            # Load NVM
            _, nvm_init_script = ensure_nvm_loaded()
            subprocess.check_output(
                ['bash', '-c', f'source {nvm_init_script} && curl -o- -L https://yarnpkg.com/install.sh | bash -s -- --version "{YARN_VERSION_TO_INSTALL}"'],
                stderr=subprocess.STDOUT,
            )

            run_command(self.install_command)
            log(Colors.OKGREEN + f'{self.name} is now installed' + Colors.ENDC)
            return True
            # Note: yarn PATH is already included in the consolidated PATH from homebrew installation
        else:
            res = run_command(self.install_command)
            log(Colors.OKGREEN + f'{self.name} is now installed' + Colors.ENDC)
            return res == 0


def parse_args():
    """Parse command line arguments."""
    parser = argparse.ArgumentParser(
        description='Install development dependencies for a new laptop.',
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog='''
Examples:
  %(prog)s              # Normal installation
  %(prog)s --dry-run    # Preview what would be installed
  %(prog)s -n           # Same as --dry-run
        '''
    )
    parser.add_argument(
        '-n', '--dry-run',
        action='store_true',
        help='Preview what would be installed without making any changes'
    )
    return parser.parse_args()


if __name__ == '__main__':
    args = parse_args()
    
    # Set dry-run flag
    DRY_RUN = args.dry_run
    
    if DRY_RUN:
        log(f"\n{Colors.BLUE}{Colors.BOLD}═══ DRY-RUN MODE ═══{Colors.ENDC}")
        log(f"{Colors.DIM}No changes will be made. Preview only.{Colors.ENDC}\n")
    
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
        Tool('awscli', 'awscli'),
        Tool('diff-so-fancy', 'diff-so-fancy'),
        Tool('lsd', 'lsd'),
        Tool('bat', 'bat'),
        Tool('fd', 'fd'),
        Tool('ag', 'silver-searcher'),
        Tool('autoupdate', 'autoupdate', 'brew install pinentry-mac && brew tap domt4/autoupdate && brew autoupdate start 18000 --cleanup --upgrade --immediate --sudo'),
    ]

    log("")  # Initial newline for spacing
    
    results = []  # Track (name, success) for summary
    
    with tqdm(tools, desc="Setting up", unit="tool", 
              bar_format="{l_bar}{bar}| {n_fmt}/{total_fmt} [{elapsed}<{remaining}]",
              colour="green", leave=False) as pbar:
        for tool in pbar:
            pbar.set_postfix_str(tool.name)
            success = tool.install()
            results.append((tool.name, success))
    
    # Print summary
    succeeded = sum(1 for _, s in results if s)
    failed = sum(1 for _, s in results if not s)
    
    log(f"\n{Colors.BOLD}{'─' * 50}{Colors.ENDC}")
    if DRY_RUN:
        log(f"{Colors.OKGREEN}✓ {succeeded} would succeed{Colors.ENDC}", end="")
        if failed:
            log(f"  {Colors.FAIL}✗ {failed} would need action{Colors.ENDC}")
            for name, success in results:
                if not success:
                    log(f"  {Colors.FAIL}  - {name}{Colors.ENDC}")
        else:
            log("")
        log(f"\n{Colors.BLUE}This was a dry-run. Run without --dry-run to install.{Colors.ENDC}")
    else:
        log(f"{Colors.OKGREEN}✓ {succeeded} succeeded{Colors.ENDC}", end="")
        if failed:
            log(f"  {Colors.FAIL}✗ {failed} failed{Colors.ENDC}")
            for name, success in results:
                if not success:
                    log(f"  {Colors.FAIL}  - {name}{Colors.ENDC}")
        else:
            log("")
        log(f"\n{Colors.BLUE}Remember to restart your terminal and/or run 'source ~/.zshrc'.{Colors.ENDC}")
    exit(0)
