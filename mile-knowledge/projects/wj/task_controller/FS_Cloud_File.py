import requests,json,time,os, matplotlib.pyplot as plt,cv2
from requests_toolbelt.multipart.encoder import MultipartEncoder 
from io import BytesIO
# 获取access_token
def get_tenant_access_token():
    app_id = "cli_a14fde5095bad00b"
    app_secret = "bHP5LfDvQJk0aPC7s2lQ8bZg8nzSxU5J"
    url = "https://open.feishu.cn/open-apis/auth/v3/tenant_access_token/internal"
    headers = {
        "Content-Type": "application/json; charset=utf-8"
    }
    data = {
        "app_id": app_id,
        "app_secret": app_secret
    }
    response = requests.post(url, headers=headers,json=data)
    return "Bearer " + json.loads(response.content)["tenant_access_token"]

print(get_tenant_access_token())

#会在第一行插入数据
sheetsid="shtcnnzBqp17gOpPrpLxurYvgyh"
def crdatap(sheetsid,strlist):
    data={"valueRange":{
    "range": "5b51c9",
    "values": [strlist]
    }
    }
    headers = {
            "Authorization":get_tenant_access_token(),
            "Content-Type": "application/json; charset=utf-8"
        }
    url=f"https://open.feishu.cn/open-apis/sheet/v2/spreadsheets/{sheetsid}/values_prepend"
    response = requests.post(url, headers=headers,json=data)
    print(response.content)
    return response.content

# 插入数据 在尾部
def crdataa(sheetsid):
    data={"valueRange":{
    "range": "5b51c9",
    "values": [
        [ "数据列表" ]
        ]}
    }
    headers = {
            "Authorization":get_tenant_access_token(),
            "Content-Type": "application/json; charset=utf-8"
        }
    url=f"https://open.feishu.cn/open-apis/sheets/v2/spreadsheets/{sheetsid}/values_append"
    response = requests.post(url, headers=headers,json=data)
    print(response.content)
    return response.content

# 上传文件 、路径
fldid="fldcngtdrtdGJbVvqWSbapylarh"# 文件夹id
def fileshangchuan(fldid,filepath):
    boundary="---7MA4YWxkTrZu0gW"
    headers = {
            "Authorization":get_tenant_access_token(),
        }
    multipart_encoder = MultipartEncoder(
        fields = {
        #这里根据服务器需要的参数格式进行修改
            "file_name": filepath.split("/")[-1],
            "parent_type": "explorer",
            "parent_node":fldid,
            "size":str(os.path.getsize(filepath)),
            "file": ('file', open(filepath, 'rb'), 'application/octet-stream')
        },
        boundary=boundary
    )

    headers['Content-Type'] = multipart_encoder.content_type
    url=f"https://open.feishu.cn/open-apis/drive/v1/files/upload_all"
    response = requests.post(url, headers=headers,data=multipart_encoder)
    print(response.content)
    return response.content

#创建文件夹 、文件夹名字
fldid="fldcngtdrtdGJbVvqWSbapylarh"# 文件夹id
def creat_folder(fldid,name):
    headers = {
            "Authorization":get_tenant_access_token(),
            "Content-Type": "application/json; charset=utf-8"
        }
    data={"title": name}
    url=f"https://open.feishu.cn/open-apis/drive/explorer/v2/folder/{fldid}"
    response = requests.post(url, headers=headers,data=data)
    print(response.content)
    return response.content

#获取文件夹下的列表
fldid="fldcngtdrtdGJbVvqWSbapylarh"# 文件夹id
def get_folder_list(fldid):
    headers = {
            "Authorization":get_tenant_access_token(),
            "Content-Type": "application/json; charset=utf-8"
        }
    url=f"https://open.feishu.cn/open-apis/drive/explorer/v2/folder/{fldid}"
    response = requests.get(url, headers=headers)
    print(response.content)
    return response.content

# 复制增加工作表 
# sheetsid 数据表格id sheetId：工作表id name：复制增加的工作表名字
sheetsid="shtcnnzBqp17gOpPrpLxurYvgyh"
sheetId="ec5581"
name="123456"
def add_sheets_batch(sheetsid,sheetId,name):
    headers = {
            "Authorization":get_tenant_access_token(),
            "Content-Type": "application/json; charset=utf-8"
        }
    data={"requests": [{
      "copySheet": {
        "source": {
          "sheetId": sheetId
        },
        "destination": {
          "title": name}}
    }]}

    url=f"https://open.feishu.cn/open-apis/sheets/v2/spreadsheets/{sheetsid}/sheets_batch_update"
    response = requests.get(url, headers=headers)
    print(response.content)
    return response.content

#写入数据到工作表
# fanwei = 需要写入数据的范围
# strlist= 写入的数据
def set_values(sheetsid,sheetId,fanwei,strlist):
    headers = {
            "Authorization":get_tenant_access_token(),
            "Content-Type": "application/json; charset=utf-8"
        }
    data={
    "valueRange":{
    "range":  f"{sheetId}!{fanwei}",
    "values": [
      strlist
    ]
    }}

    url=f"https://open.feishu.cn/open-apis/sheets/v2/spreadsheets/{sheetsid}/values"
    response = requests.get(url, headers=headers)
    print(response.content)
    return response.content


# def values_image(filepath):
#     headers = {
#             "Authorization":get_tenant_access_token(),
#             "Content-Type": "application/json; charset=utf-8"
#         }
#     data={ 
#     "range": "5b51c9!C1:C1", 
#     "image": np.array(cv2.imread(filepath)).flatten(),
#     "name": "123.jpg"}

#     url=f"https://open.feishu.cn/open-apis/sheets/v2/spreadsheets/shtcnnzBqp17gOpPrpLxurYvgyh/values_image"
#     response = requests.post(url, headers=headers,data=data)
#     print(response.content)
#     return response.content
    
# filepath="C:/Users/admin/Desktop/123.jpg"
# values_image(filepath)
# print(type(cv2.imread(filepath)))