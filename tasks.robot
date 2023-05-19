*** Settings ***
Documentation       Orders robots from RobotSpareBin Industries Inc.
...                 Saves the order HTML receipt as a PDF file.
...                 Saves the screenshot of the ordered robot.
...                 Embeds the screenshot of the robot to the PDF receipt.
...                 Creates ZIP archive of the receipts and the images.

Library             RPA.Browser.Selenium    auto_close=${FALSE}
Library             RPA.HTTP
Library             RPA.Tables
Library             RPA.PDF
Library             RPA.Archive
Library             RPA.RobotLogListener
Library             OperatingSystem


*** Variables ***
${PDF_TEMP}=            ${CURDIR}${/}pdf_temp
${SCREENSHOT_TEMP}=     ${CURDIR}${/}screenshot_temp
${PDF_FINAL}=           ${CURDIR}${/}pdf_final


*** Tasks ***
Order robots from RobotSpareBin Industries Inc
    Set up directories
    Open the robot order website
    Download file with expected orders
    Pass orders from csv file
    Close browser
    Create zip file and delete unnecessary directories


*** Keywords ***
Set up directories
    Create Directory    ${PDF_TEMP}
    Create Directory    ${SCREENSHOT_TEMP}
    Create Directory    ${PDF_FINAL}

Open the robot order website
    Open Available Browser    https://robotsparebinindustries.com/#/robot-order

Download file with expected orders
    Download    https://robotsparebinindustries.com/orders.csv    overwrite=True

Pass orders from csv file
    ${Orders}    Read table from CSV    orders.csv    header=${True}
    FOR    ${order}    IN    @{orders}
        Close the annoying modal
        Select order specifications    ${order}
        Press preview and confirm order
        Take screenshot and safe receipt as pdf file    ${order}
        Append screenshot into pdf file, append receipt to zip and order next bot    ${order}
    END

Close the annoying modal
    Click Button    css:button[class="btn btn-dark"]

 Select order specifications
    [Arguments]    ${order}
    #Select head type
    Select From List By Value    head    ${order}[Head]
    #Select body type
    ${bodyType}    Set Variable    ${order}[Body]
    Click Element    //label[./input[@value="${bodyType}"]]
    #Select number of legs
    Input Text    css:input[class="form-control"]    ${order}[Legs]
    #Input Adress
    Input Text    address    ${order}[Address]

Check if error event happened
    ${bodyType}    Does Page Contain Element    css:div[class="alert alert-danger"]

    #If there is error event try to complete order untill it get accepted
    WHILE    ${bodyType}
        Click Button    order
        ${bodyType}    Does Page Contain Element    css:div[class="alert alert-danger"]
    END

Press preview and confirm order
    #Ask for robot preview
    Click Button    preview
    #Confirm order
    Click Button    order
    #Check if there is any error event
    Check if error event happened
    #Sometimes bot goes too fast with next step
    Sleep    0.3

Take screenshot and safe receipt as pdf file
    [Arguments]    ${order}
    #Take screenshot of robot the preview
    Wait Until Element Is Visible    id:robot-preview-image
    #Set variables that are used in safe path
    ${document_title}    Set Variable    robot_preview_
    ${document_type}    Set Variable    .png
    Log    ${document_title}${order}[Order number]${document_type}
    Screenshot
    ...    id:robot-preview-image
    ...    ${SCREENSHOT_TEMP}${/}${document_title}${order}[Order number]${document_type}
    #Get receipt html
    Wait Until Element Is Visible    id:receipt
    ${sales_receipt_html}    Get Element Attribute    id:receipt    outerHTML
    #Save receipt as pdf file
    #Set variables that are used in safe path
    ${document_title}    Set Variable    sales_receipt_
    ${document_type}    Set Variable    .pdf
    Html To Pdf    ${sales_receipt_html}    ${PDF_TEMP}${/}${document_title}${order}[Order number]${document_type}

Append screenshot into pdf file, append receipt to zip and order next bot
    [Arguments]    ${order}
    ${document_title_1}    Set Variable    robot_preview_
    ${document_type_1}    Set Variable    .png
    ${document_title_2}    Set Variable    sales_receipt_
    ${document_type_2}    Set Variable    .pdf
    ${document_title_3}    Set Variable    full_receipt_

    ${files}    Create List
    ...    ${PDF_TEMP}${/}${document_title_2}${order}[Order number]${document_type_2}
    ...    ${SCREENSHOT_TEMP}${/}${document_title_1}${order}[Order number]${document_type_1}
    Add Files To PDF    ${files}    ${PDF_FINAL}${/}${document_title_3}${order}[Order number]${document_type_2}
    Click Button    order-another

Create zip file and delete unnecessary directories
    Archive Folder With Zip    ${PDF_FINAL}    ${OUTPUT_DIR}${/}output_recipes.zip
    Empty Directory    ${PDF_TEMP}
    Empty Directory    ${SCREENSHOT_TEMP}
    Empty Directory    ${PDF_FINAL}
    Remove Directory    ${PDF_TEMP}
    Remove Directory    ${SCREENSHOT_TEMP}
    Remove Directory    ${PDF_FINAL}
