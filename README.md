# Publish On 4PDA

<img src="https://user-images.githubusercontent.com/8808766/95100080-6725e880-0739-11eb-9420-a333c28661e3.png" width ="128"/>

A command-line utility for publishing new release on 4pda.

## Run

Command to print usage information.
```
dart bin/main.dart --help
```
Result:
```
A command-line utility for publishing new release on 4pda.

Options:
-P, --pass-hash             "pass_hash" cookie header.
-M, --member-id             "member_id" cookie header.
-T, --topic-id              "topic_id" of topic where to post.
-C, --directory             Directory from which to take files.
-E, --dir-files-ext         Directory files filter by extension. Example:
                            --dir-files-ext apk
                            Only works with --directory option.
-F, --files                 Another approach to --directory with --dir-files-ext.
                            Uses only if --directory option doesn't exist.
                            Relative or absolute path to file to attach.
                            For multiple files: 
                            --files a,b 
                            OR 
                            --files a --files b
                            allowed ext.: apk, apks, exe, zip, rar, obb, 7z, r00, r0
                            max files size: 192Mb
-V, --version-in-post       What to paste in "version" field in the post
-S, --short-description     What to paste in "short description" field in post
-D, --description           What to paste in "description" field in post
-N, --package-name          If you want to rename your files in style:
                            package-name + "." + version-in-post + "_" + arch (if .apk) + file-extension
                            If there is no arch in original filename pastes "arm7" by default.
                            Example result: "flibusta.0.6.5_arm7.apk"

Flags:
-h, --help                 Print this usage information.
```
