#!/bin/sh

set -ue

RepositoryName="${INPUT_REPOSITORY_NAME}"
AwsRegion="${INPUT_AWS_REGION}"
SourceBranch="${INPUT_SOURCE_BRANCH}"
DestinationBranch="${INPUT_DESTINATION_BRANCH}"
FoldersToCopy="${INPUT_FOLDERS_TO_COPY}"
github_after="${INPUT_GITHUB_AFTER}" 
github_before="${INPUT_GITHUB_BEFORE}" 
automated_user_name="${INPUT_AUTOMATED_USER_NAME}" 
automated_user_email="${INPUT_AUTOMATED_USER_EMAIL}" 

CodeCommitUrl="https://git-codecommit.${AwsRegion}.amazonaws.com/v1/repos/${RepositoryName}"
CommitMessage="syncing commits for range ${github_before} to ${github_after}"

git config --global --add safe.directory /github/workspace
git config --global credential.'https://git-codecommit.*.amazonaws.com'.helper '!aws codecommit credential-helper $@'
git config --global credential.UseHttpPath true

#Configuring source repository with the input branch
cd /github/workspace/
git checkout "$SourceBranch"

#Configuring destination repository with the destination branch
cd /
git clone "$CodeCommitUrl"
cd "$RepositoryName"
git checkout "$DestinationBranch"

if [ -z "$FoldersToCopy" ]
then
    echo "folders to copy not sepcified. Copying entire repo"
    cp -r "/github/workspace/"* .  
else
    for folder in $FoldersToCopy
    do
        echo "copyng folder - ${folder}"
        cp -r "/github/workspace/$folder" .
    done
fi

git config user.email "$automated_user_email"
git config user.name "$automated_user_name" 

git remote add sync ${CodeCommitUrl}
git add .
git commit -m "${CommitMessage}"
git push sync ${DestinationBranch}
