# apim-distributed-dev-setup

This repository provides a straightforward setup for a distributed API Management (APIM) development environment. Begin by copying the required packs into the `components` directory. **Note:** The directory names must strictly follow the naming convention: `wso2am-acp`, `wso2am-tm`, and `wso2am-universal-gw`. 

When you execute the startup script, it initializes a MySQL Docker container and runs the scripts located in `conf/mysql/scripts`. Subsequently, the APIM components are launched with the configurations specified below:

- **APIM-ACP**: Zero offset
- **APIM-TM**: Offset of 1
- **APIM-Universal-GW**: Offset of 2

### Prerequisites

- Docker Engine 20.10.x or newer
- Docker Compose v2.x or newer
- APIM packs

### Getting Started

1. Clone the repository:
    ```bash
    git clone https://github.com/yourusername/apim-distributed-dev-setup.git
    cd apim-distributed-dev-setup
    ```
2. Extract the packs into the `components` directory:
    Ensure the packs are placed in the `components` directory with the following exact folder names:
    - `wso2am-acp`
    - `wso2am-tm`
    - `wso2am-universal-gw`
    ```
    components
    ├── wso2am-acp
    ├── wso2am-tm
    └── wso2am-universal-gw
    ```

3. Build and start the APIM distributed setup:
    ```bash
    sh run.sh start --seed  # The `--seed` argument ensures that the database scripts are executed during startup.
    ```

4. Start the distributed setup without executing the database scripts:
    ```bash
    sh run.sh start
    ```

5. Access the portals at the following URLs:
    ```
    Control Plane: https://localhost:9443
    Gateway: https://localhost:8245
    ```

6. Stop the services:
    ```bash
    sh run.sh --stop
    ```

### Environment Configuration

To update any configuration files in the `conf/repository` directory of the packs, make the changes in the `conf/repository` directory. These updates will be automatically copied to the required location when you execute the `run.sh` script.

### Troubleshooting

- Logs for each APIM component can be found in the `logs/` directory. 
- To terminate all WSO2 Java services, use the following command:
    ```bash
    ps -ef | grep 'wso2' | grep -v grep | awk '{print $2}' | xargs -r kill -9
    ```
- If you encounter a database issue, retry the operation. 
- If you see an error in starting up the servers when the script runs because of exceeding the retry count, wait for some time and try accessing the APIM server urls. This is because the servers could be taking more time to start than ususal in your machine. You can check the logs from the `/logs` directory in the cloned repo to make sure the servers have started.