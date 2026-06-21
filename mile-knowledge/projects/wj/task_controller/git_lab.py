# coding=utf-8
import gitlab, os, time, json
from gitlab.v4.objects.projects import Project

# CONFIGJSON = 'config.json'


class GitLab:
    def __init__(self,gitlaburl="https://gitlab.testplus.cn/",token="aJzWskeJWm8C8Bo8gERn"):
        # log.initLog('git_lab')
        # dicConfig = self.readJsonFile(CONFIGJSON)
        self.gl = gitlab.Gitlab(url=gitlaburl,
                                private_token=token)

    def readJsonFile(self, path) -> dict:
        # with open(path, 'r', encoding='utf-8') as f:
        #     try:
        #         return json.loads(f.read())
        #     except json.decoder.JSONDecodeError:
        #         return {}
        return {"gitlab":{"gitlaburl":"https://gitlab.testplus.cn/","token":"aJzWskeJWm8C8Bo8gERn"}}

    def getProjectById(self, sId) -> Project:
        """通过 id 获取 仓库"""
        return self.gl.projects.get(sId)

    def getProjectByName(self, sName) -> Project or None:
        """通过 name 获取 仓库
        如果有过多的相似名称的项目 可能会匹配错误"""
        Projectlist=self.gl.projects.list(search=sName)
        if len(Projectlist) == 0:
            return None
        elif len(Projectlist)>1:
            for Project in Projectlist:
                print(Project.name)
                if Project.name==sName:
                    return Project
            return Projectlist[0]
        elif len(Projectlist)==1:
            return Projectlist[0]

    def getProjectIdByUrl(self, sUrl:str) -> Project or None:
        """通过url检索所有的"""
        gitlab_project_id={}
        sUrl=sUrl.replace(".git","")
        if os.path.isfile("project_id.json"):
            with open("project_id.json", 'r', encoding='utf-8') as f:
                data=f.read()
                if data!="":
                    gitlab_project_id= json.loads(data)
            if sUrl in gitlab_project_id:
                return gitlab_project_id[sUrl]
            else:
                print("本地检索不到该项目",sUrl,"尝试重试拉取整个项目的id")
                gitlab_project_id=self.getProjectIdAll()
        else:
            gitlab_project_id=self.getProjectIdAll()
            with open("project_id.json", 'r', encoding='utf-8') as f:
                gitlab_project_id= json.loads(f.read())
            if sUrl in gitlab_project_id:
                return gitlab_project_id[sUrl]
        return None
    
    def getProjectIdAll(self) -> dict:
        gitlab_project_id={}
        """通过地址 检索仓库 并存储id到本地"""
        print('检索所有git仓库 并拉取id')
        for dicProject in self.gl.projects.list(all=True):
            gitlab_project_id[dicProject.web_url]=dicProject.id
        with open("project_id.json", 'w', encoding='utf-8') as f:
            f.write(json.dumps(gitlab_project_id))

        return gitlab_project_id
    
    class GitLabProject:
        def __init__(self, classProject: Project):
            self.Project = classProject
            self.sName = classProject.name
            self.sId = classProject.id
            self.sGitHttp = classProject.http_url_to_repo  # https://gitlab.testplus.cn/mali/AUTO_WEB_FLASK.git
            self.sHttp = classProject.web_url  # https://gitlab.testplus.cn/mali/AUTO_WEB_FLASK
            self.SHA=classProject.default_branch
            self.specifySha=False

        def getFileContent(self, sFilePath):
            """返回文件二进制流"""
            try:
                return self.Project.files.get(sFilePath, ref=self.SHA).decode()
            except gitlab.GitlabGetError as e:
                print("拉取文件：{} 错误：{}".format(sFilePath, e))
        def set_sha(self,SHA):
            print("指定更新代码到",SHA)
            self.specifySha=True
            self.SHA=SHA

        def get_project_sha(self):
            if self.specifySha:
                return self.SHA,"指定sha更新"
            latest_commit = self.Project.commits.list(get_all=False,order_by='created_at', sort='desc', per_page=1)[0]
            print("SHA为",latest_commit.id,"提交摘要为",latest_commit.message)
            return latest_commit.id,latest_commit.message

        def get_Local_sha(self,sPullPath):
            # return ""
            if os.path.exists(f"{sPullPath}/sha"):
                with open(f"{sPullPath}/sha","r") as f:
                    date=f.read()
                    print("本地sha地址为",date)
                    return date
            else:
                print("本地文件不存在")
                return ""
        def set_Local_sha(self,sPullPath,sha):
            with open(f"{sPullPath}/sha","w") as f:
                date=f.write(sha)
                print(date)
                # return date


        def pullCode(self, sPullPath,filepath=""):
            """
            拉取仓库代码 \n sPullPath 是相对路径,最终的文件路径为：python的工作路径 + sPullPath
            filepath: 指定要拉取的文件夹
            """
            print("开始拉取仓库")
            sWorkPath = os.getcwd()
            try:
                self._createDir(sPullPath)
                if filepath !="":self._createDir(os.path.join(sPullPath,filepath))
                Local_sha=self.get_Local_sha(sPullPath)
                project_sha,message=self.get_project_sha()
                print(Local_sha,project_sha)
                if Local_sha==project_sha:
                    print("本地代码以满足需求 不需要更新")
                    return ""
                else:
                    print("sha不一致需要修改一波",message)
                # os.chdir(sPullPath)
                aFileList = self.Project.repository_tree(ref=self.SHA,path=filepath, all=True, recursive=True, iterator=False )
                def _(dicFile):
                    abs_path = os.path.join(sPullPath, dicFile['path'])
                    if dicFile['type'] == 'tree':
                        self._createDir(abs_path)
                    else:
                        with open(abs_path, 'wb') as f:
                            f.write(self.getFileContent(dicFile['path']))

                for i in aFileList:
                    _(i)
                print("仓库拉取完毕-",project_sha)
                # self.set_Local_sha(project_sha)
            finally:
                # os.chdir(sWorkPath)
                pass

        def _createDir(self, sDirName):
            if not os.path.isdir(sDirName):
                os.makedirs(sDirName)
                print("创建路径:{}".format(sDirName))
                time.sleep(0.1)

        
if __name__ == '__main__':
    # obj = GitLab()
    # t = obj.GitLabProject(obj.getProjectByName("mecha"))
    # https://gitlab.testplus.cn/mali/AUTO_WEB_FLASK
    # https://gitlab.testplus.cn/mali/AUTO_WEB_FLASK.git
    # id=obj.getProjectIdByUrl("https://gitlab.testplus.cn/UAuto/mecha.git")
    # project=obj.getProjectByName("mecha")
    # print("获取到项目id为", project.id) 
    # t.set_sha("1ab3a9a2b4ed60164dffcbcce5cf72a1b5bdc168")
    # t.pullCode("mecha","pages")
    # print(t.Project)
    # latest_commit = t.Project.commits.list(get_all=False,order_by='created_at', sort='desc', per_page=1)[0]
    # print("SHA为",latest_commit.id,"提交摘要为",latest_commit.message)
    obj=GitLab()
    project=obj.GitLabProject(obj.getProjectByName('tgame'))

    branch = "master"

    branches=project.Project.branches.list()
    for progect in branches:
        if branch == progect.get_id():
            print(progect._attrs)
            # info=progect.to_json()
            # print(info)
            # self.bot.send_text(f"{self.device_name} 执行代码分支: {self.branch} 提交SHA：{info['commit']['id']}")
            # print(info["commit"]["id"],info["commit"]["message"])
            # self.local_sha = f"{self.branch}/{info['commit']['id']}"

            break


    # print(project.Project.default_branch)
    # self.asdict()
    # sha = "R202212"
    # # if sha != None:
    # #     project.set_sha(sha)
    # print("获取到项目id为", project.sId,"开始更新pages脚本代码")
    # print(project)
    # print(project.Project.branches)
    # latest_commit = project.Project.commits.list(get_all=False,order_by='created_at', sort='desc', per_page=1, ref=sha)[0]
    # print("SHA为",latest_commit.id,"提交摘要为",latest_commit.message)
    # project.pullCode('tgame')
