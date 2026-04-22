<%@ WebHandler Language="C#" Class="下載" %>
using System;
using System.IO;
using System.Web;

public class 下載 : IHttpHandler
{
    public void ProcessRequest(HttpContext context)
    {
        try
        {
            if (!權限輔助.要求登入(context)) return;

            string IP = IP輔助.取得用戶端IP();
            string idStr = context.Request.QueryString["id"];
            
            if (string.IsNullOrEmpty(idStr)) { context.Response.StatusCode = 400; return; }
            
            int 檔案編號 = int.Parse(idStr);
            
            var dt = 資料庫輔助.查詢(
                "SELECT 原始檔名, 檔案路徑, 副檔名, 是否刪除, 儲存區類型, 組別編號, 審核狀態 FROM 檔案主檔 WHERE 檔案編號=@id",
                資料庫輔助.P("@id", 檔案編號));
            
            if (dt.Rows.Count == 0)
            {
                操作紀錄輔助.記錄(檔案編號, "下載", IP, "失敗", "檔案不存在");
                context.Response.StatusCode = 404; return;
            }
            
            var row = dt.Rows[0];
            if (!權限輔助.可存取檔案(row))
            {
                操作紀錄輔助.記錄(檔案編號, "下載", IP, "失敗", "無下載權限");
                context.Response.StatusCode = 403;
                return;
            }
            bool 已刪除 = Convert.ToBoolean(row["是否刪除"]);
            if (已刪除) { context.Response.StatusCode = 410; return; }
            
            string 路徑 = row["檔案路徑"].ToString();
            string 原始檔名 = row["原始檔名"].ToString();
            
            if (!File.Exists(路徑))
            {
                操作紀錄輔助.記錄(檔案編號, "下載", IP, "失敗", "實體檔案不存在");
                context.Response.StatusCode = 404; return;
            }

            操作紀錄輔助.記錄(檔案編號, "下載", IP, "成功", null, 原始檔名);

            context.Response.Clear();
            context.Response.ContentType = "application/octet-stream";
            context.Response.AddHeader("Content-Disposition",
                $"attachment; filename*=UTF-8''{Uri.EscapeDataString(原始檔名)}");
            context.Response.AddHeader("Content-Length", new FileInfo(路徑).Length.ToString());
            context.Response.TransmitFile(路徑);
            context.Response.End();
        }
        catch (System.Threading.ThreadAbortException)
        {
        }
        catch (Exception ex)
        {
            例外處理輔助.記錄例外(ex, "下載例外", "Handlers/下載.ashx");
            context.Response.StatusCode = 500;
        }
    }

    public bool IsReusable { get { return false; } }
}
