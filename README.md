# aurorafin-shared

This is consumed by [aurora-common](https://github.com/get-aurora-dev/common) and [bluefin-common](https://github.com/projectbluefin/common) as a git submodule.

## Why?

The [shared directory](https://github.com/projectbluefin/common/tree/3284cfe5302be1c4aae3484484f446292f782f20/system_files/shared) inside Bluefin (used by Aurora) didn't really work that well because it meant for Aurora to always keep an eye out for the few PRs out of the many that changed things in this shared directory. It's easy to make this mistake and forget that it is agnostic to the desktop and shared with Aurora for a Repository in projectbluefin. Also I want to keep the AI slop out lol.
