$patToken = "removed-pat-token"
$username = "Shiazy18"
$repository = "Feedback-form"


$base64AuthInfo = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes(":$($patToken)"))

# Get a list of all branches in the repository
$branchListUrl = "https://api.github.com/repos/$username/$repository/branches"
$branches = Invoke-RestMethod -Uri $branchListUrl -Headers @{Authorization=("Basic {0}" -f $base64AuthInfo)}

# Define the date 1 week ago
$oneWeekAgo = (Get-Date).AddDays(-7)

# Initialize an array to store branches for deletion
$branchesToDelete = @()

# Loop through the branches and check if they are not 'main' or 'release'
foreach ($branch in $branches) {
    $branchName = $branch.name
    if ($branchName -ne "main" -and $branchName -ne "release") {
        # Get the branch's last commit date
        $commitUrl = "https://api.github.com/repos/$username/$repository/commits/$branchName"
        $commit = Invoke-RestMethod -Uri $commitUrl -Headers @{Authorization=("Basic {0}" -f $base64AuthInfo)}
        $commitDate = [DateTime]::ParseExact($commit.commit.author.date, "yyyy-MM-ddTHH:mm:ssZ", $null)
        
        # Check if the branch is older than 1 week
        if ($commitDate -lt $oneWeekAgo) {
            Write-Host "Branch '$branchName' is older than 1 week and will be deleted."
            $branchesToDelete += $branchName
        } else {
            Write-Host "Branch '$branchName' is not older than 1 week and will not be deleted."
        }
    }
}

# Delete branches that are older than 1 week
foreach ($branchToDelete in $branchesToDelete) {
    Write-Host "Deleting branch: $branchToDelete"
    
    # Delete the branch using the GitHub API
    $deleteBranchUrl = "https://api.github.com/repos/$username/$repository/git/refs/heads/$branchToDelete"
    Invoke-RestMethod -Uri $deleteBranchUrl -Headers @{Authorization=("Basic {0}" -f $base64AuthInfo)} -Method Delete
}

Write-Host "Branch deletion completed."
