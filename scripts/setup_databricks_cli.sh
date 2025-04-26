#!/bin/bash
# Databricks CLI Setup Script
# This script helps configure the Databricks CLI for your environment

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}Databricks CLI Setup Script${NC}"
echo "============================"

# Check if Databricks CLI is installed
if ! command -v databricks &> /dev/null; then
    echo -e "${YELLOW}Databricks CLI not found. Installing it now...${NC}"
    pip install databricks-cli
    
    if [ $? -ne 0 ]; then
        echo "Failed to install databricks-cli with pip."
        echo "Please install it manually with: pip install databricks-cli"
        exit 1
    fi
    
    echo -e "${GREEN}Databricks CLI installed successfully!${NC}"
fi

# Extract workspace URL and PAT token from dev.tfvars
DEV_TFVARS="environments/dev.tfvars"
WORKSPACE_URL="https://adb-1922282054820805.5.azuredatabricks.net/"
PAT_TOKEN="dapi316746185f69edf64bf80a971809ace4-3"

if [ -f "$DEV_TFVARS" ]; then
    echo "Found dev.tfvars file. Extracting PAT token..."
    PAT_TOKEN=$(grep "databricks_pat" "$DEV_TFVARS" | cut -d'"' -f2)
    
    if [ -n "$PAT_TOKEN" ]; then
        echo -e "${GREEN}Found PAT token in dev.tfvars.${NC}"
    else
        echo -e "${YELLOW}Could not extract PAT token from dev.tfvars.${NC}"
    fi
else
    echo -e "${YELLOW}dev.tfvars file not found.${NC}"
fi

# Create Databricks CLI configuration
echo "Configuring Databricks CLI..."
echo "Workspace URL: $WORKSPACE_URL"

# Create ~/.databrickscfg file
cat > ~/.databrickscfg << EOL
[DEFAULT]
host = $WORKSPACE_URL
EOL

# Add token if we have it, otherwise prompt
if [ -n "$PAT_TOKEN" ]; then
    echo "token = $PAT_TOKEN" >> ~/.databrickscfg
    echo -e "${GREEN}Added PAT token to configuration.${NC}"
else
    echo "Please enter your Databricks PAT token:"
    read -s input_token
    echo "token = $input_token" >> ~/.databrickscfg
    echo -e "${GREEN}Added provided token to configuration.${NC}"
fi

# Test the configuration
echo "Testing Databricks CLI configuration..."
if databricks workspace ls &> /dev/null; then
    echo -e "${GREEN}Databricks CLI configured successfully!${NC}"
    echo "You can now use the Databricks CLI with your workspace."
else
    echo -e "${YELLOW}Configuration test failed. Please check your workspace URL and token.${NC}"
    echo "You may need to run 'databricks configure --token' and provide:"
    echo "  Host: $WORKSPACE_URL"
    echo "  Token: Your PAT token"
fi