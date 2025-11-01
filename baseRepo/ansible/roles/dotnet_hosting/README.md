Ansible role: dotnet_hosting

Purpose: Install .NET 8 Hosting Bundle on Windows targets.

Usage:
- Include the role in the playbook that targets the ASG instances (inventory can be dynamic via ec2 plugin or SSM plugin).
- Ensure WinRM or SSM connectivity is available.

Tasks provided:
- download-and-install: Download the official hosting bundle and run it silently.

Notes:
- This role intentionally only installs the Hosting Bundle. IIS is expected to be pre-baked in the AMI.
- Adjust the download URL to the correct version/channel for your environment.
