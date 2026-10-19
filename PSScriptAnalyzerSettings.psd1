@{
    # Default PSScriptAnalyzer rules, errors and warnings.
    Severity     = @('Error', 'Warning')
    ExcludeRules = @(
        # The provisioning scripts are run interactively by an admin and use
        # Write-Host for status messages only. Data (reports) is always
        # returned as objects on the pipeline.
        'PSAvoidUsingWriteHost'
    )
}
