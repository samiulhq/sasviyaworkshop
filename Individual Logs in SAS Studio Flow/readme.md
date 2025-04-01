# Create Individual Logs for SAS Codes in a Flow

## Description
We introduce a custom step, "Run SAS Code," that enables users to generate individual log files for programs within a flow in SAS Studio. This custom step facilitates better tracking and debugging by segregating logs for each program executed in a sequence.

## Features
- **Individual Log Files**: Generate separate log files for each SAS program in your flow.
- **Easy Integration**: Easily incorporate the custom step into existing SAS Studio workflows.
- **Enhanced Debugging**: Simplify debugging processes with segregated logs.
- **Clincal Programming Workflow**: Replicate clinical programming steps in a structured way using SAS Studio flow.
## Requirements
- SAS Studio on SAS Viya
- Access rights to upload custom steps

## Installation
1. **Download the Custom Step**: Download the `Run_SAS_Code_Step.stp` file from this repository.
2. **Upload to SAS Studio**:
   - Navigate to SAS Studio on SAS Viya
   - Right click to a folder where you have write permission
   - Upload the downloaded step file
   -![Uploading Step File on SAS Studio](https://github.com/samiulhq/sasviyaworkshop/blob/main/Individual%20Logs%20in%20SAS%20Studio%20Flow/upload%20files.png)
   - Drag or insert the custom step into SAS Studio flow.
   - ![Drag step into flows](https://github.com/samiulhq/sasviyaworkshop/blob/main/Individual%20Logs%20in%20SAS%20Studio%20Flow/custom%20step%20into%20flow.png)

## Usage
To utilize the "Run SAS Code" custom step within your flow, follow these steps:

1. **Incorporate the Custom Step**:
   - Drag and drop the "Run SAS Code" step into your flow workspace.
2. **Configure the Step**:
   - Point the step to your SAS code by specifying the file path or using the code editor.
3. **Repeat for Multiple Programs**:
   - Repeat steps 1 and 2 for each SAS program you want to include in the flow.
4. **Create Swimlanes**:
   - Organize your steps into swimlanes for sequential or parallel execution as required.

## Example
Below is an example flow that demonstrates how to use the "Run SAS Code" custom step within a SAS Studio flow:
![Example Flow](https://github.com/samiulhq/sasviyaworkshop/blob/main/Individual%20Logs%20in%20SAS%20Studio%20Flow/logs_flow.png)

## Contributing
Contributions to this project are welcome! Please review our contributing guidelines in the `CONTRIBUTING.md` file before submitting any pull requests or issues.

## License
This project is licensed under the MIT License - see the [LICENSE.md](https://github.com/samiulhq/sasviyaworkshop/blob/main/LICENSE) file for details.

## Authors and Acknowledgment
- **Samiul Haque** - *Initial work* - [Samiul Haque](https://github.com/samiulhq/)


## Support
For support, email us at [samiul.haque@live.com] or raise an issue in this repository.

## FAQ
Q: Can I use this custom step with any version of SAS Studio?  
A: This step is compatible with SAS Studio Version X.X and higher.

