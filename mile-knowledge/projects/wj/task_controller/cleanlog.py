from minio import Minio
import mysql.connector
from datetime import datetime, date
from datetime import timedelta


def get_date(days:int):
    print(datetime.now().strftime("%Y-%m-%dT%H:%M:%S"),": 开始执行")
    return (datetime.now() - timedelta(days=days)).strftime("%Y-%m-%dT%H:%M:%S")


if __name__ == '__main__':
    select_date=get_date(5)
    mydb = mysql.connector.connect(
        host="10.11.10.200",
        user="mobile_autotest_reader",
        password="KINGsoft+5688",
        database="mobile_autotest_prod"
        )
    mycursor = mydb.cursor()

    mycursor.execute(f"SELECT id FROM task_running WHERE task_running.create_time <= '{select_date}' ORDER BY task_running.id DESC LIMIT 1")
    if mycursor!=[]:
        myresult = mycursor.fetchall()[0][0]

        mycursor.close()
        print(f"开始清除 {myresult} 之前的数据")
        datasize=0
        n=0
        # 日志清除
        bucket_name="auto-log"
        minioClient = Minio("10.11.81.196:9000",access_key="lin",secret_key="lin123$%^",secure=False)
        objects = minioClient.list_objects(bucket_name,recursive=True)
        data={}
        for obj in objects:
            name=obj.object_name
            if "excel" not in name and int(name.split("/")[0].split("-")[-1]) <=int(myresult):
                n+=1
                datasize+=int(obj.size)
                minioClient.remove_object(bucket_name, obj.object_name)
                print(name)
        print(f"一共清除了{n}个文件,清理出 {datasize/1024/1024} MB空间")