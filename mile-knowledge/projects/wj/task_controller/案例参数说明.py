# 额外信息
# 自动化服务器
server_url = "https://uauto-api.testplus.cn"#子设备获取案例的地址


#案例参数
item="返回信息的data的一项"
device = item["device"]
package_url = item["package_url"]
package_info=item["package_info"]
task_running_id = item["task_running_id"]
task_parameters = item["task_parameters"]
project_id = item["project_id"]
feishu_token = item["feishu_token"]

# 案例所需要参数
(device["device_identifier"], device["ip"], device["os"], device["port"], package_url, package_info, device["id"],device["quality"], task_running_id,task_parameters, project_id, feishu_token, "文件锁先不管", "多进程通信管理先不管", server_url)