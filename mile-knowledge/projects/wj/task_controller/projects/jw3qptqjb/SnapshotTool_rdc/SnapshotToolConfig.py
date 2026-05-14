GatherToolsUrl={
    "memoryflames":"http://10.11.10.129:9000/forupdate/VallocMon_V2.0.2.zip",
    "renderdoc":"https://minio-cluster.testplus.cn/firingsrv-bucket/autoRenderdoc.exe",
    "unity":"https://minio-cluster.testplus.cn/firingsrv-bucket/Unity.zip",
    "wpsrobot":"https://xz.wps.cn/api/v1/webhook/send?key=925366935f4fd8405101b739d3f527f1",
    "Symtools":"https://minio-cluster.testplus.cn/firingsrv-bucket/Symtools.zip",
    "official_rdc":"http://10.11.10.129:9000/forupdate/RenderDoc_1.29_64.msi"
}

ConnectServers={
    "memoryflames":"127.0.0.1:45132",
    "renderdoc":"127.0.0.1:20621",
    "memoryanalyzesnap1":"127.0.0.1:6620",
    "memoryanalyzesnap2":"127.0.0.1:6621",
    "memoryanalyzesnap3":"127.0.0.1:6622"
}

ConnectPort={
    "memoryflames":45132,
    "renderdoc":20621,
}

Memory_Upload={
    "Upload_Url":"http://10.11.67.163:5566/api/v2/report/upload/url",
    "Analyze_Url":"http://10.11.67.163:5566/api/v2/report/analysis"
}

GPU_Upload={
    "Upload_Url":"http://10.11.10.40:5577/api/report/upload/url",
    "Analyze_Url":"http://10.11.10.40:5577/api/report/analysis"
}

# 正式环境
# "Upload_Url":"http://10.11.67.163:5566/api/report/upload/url",
# "Analyze_Url":"http://10.11.67.163:5566/api/report/analysis"

# 测试环境
# "Upload_Url":"http://10.11.81.198:5567/api/v2/report/upload/url",
# "Analyze_Url":"http://10.11.81.198:5567/api/v2/report/analysis"