<%@ WebHandler Language="C#" Class="資料夾樹" %>
using System;
using System.Web;

/// <summary>
/// 回傳資料夾子節點 JSON，供前端樹狀選擇器 Ajax 呼叫
/// </summary>
public class 資料夾樹 : IHttpHandler
{
    public void ProcessRequest(HttpContext context)
    {
        context.Response.ContentType = "application/json";
        context.Response.ContentEncoding = System.Text.Encoding.UTF8;

        if (!權限輔助.要求登入(context)) return;

        string 父id = context.Request.QueryString["父id"];
        string 組別 = context.Request.QueryString["組別"];
        string 儲存區 = context.Request.QueryString["儲存區"];
        if (!權限輔助.可查看儲存區(儲存區))
        {
            權限輔助.回應錯誤(context, 403, "沒有此儲存區的查看權限");
            return;
        }

        int? 父編號 = string.IsNullOrEmpty(父id) ? (int?)null : int.Parse(父id);
        int? 組別編號 = string.IsNullOrEmpty(組別) ? (int?)null : int.Parse(組別);
        if (!角色輔助.是管理員())
            組別編號 = 帳號輔助.取得組別編號();

        string json = 資料夾輔助.產生樹JSON(父編號, 組別編號, 儲存區);
        context.Response.Write(json);
    }
    public bool IsReusable { get { return false; } }
}
