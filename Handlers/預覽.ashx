<%@ WebHandler Language="C#" Class="預覽" %>
using System;
using System.IO;
using System.Text;
using System.Web;

public class 預覽 : IHttpHandler
{
    private static readonly string[] 圖片格式 = { ".jpg", ".jpeg", ".png", ".gif", ".bmp", ".webp" };
    private static readonly string[] 文字格式 = { ".txt", ".log", ".csv", ".xml", ".json", ".html", ".htm" };

    public void ProcessRequest(HttpContext context)
    {
        try
        {
            if (!權限輔助.要求登入(context)) return;

            string IP = IP輔助.取得用戶端IP();
            string idStr = context.Request.QueryString["id"];
            string action = context.Request.QueryString["action"];
            
            if (string.IsNullOrEmpty(idStr)) { context.Response.StatusCode = 400; return; }
            int 檔案編號 = int.Parse(idStr);

            var dt = 資料庫輔助.查詢(
                "SELECT 原始檔名, 檔案路徑, 副檔名, 檔案類型, 儲存區類型, 組別編號, 審核狀態 FROM 檔案主檔 WHERE 檔案編號=@id AND 是否刪除=0",
                資料庫輔助.P("@id", 檔案編號));
            
            if (dt.Rows.Count == 0) { context.Response.StatusCode = 404; return; }
            var row = dt.Rows[0];
            if (!權限輔助.可存取檔案(row))
            {
                操作紀錄輔助.記錄(檔案編號, "預覽", IP, "失敗", "無預覽權限");
                context.Response.StatusCode = 403;
                return;
            }

            if (action == "log")
            {
                操作紀錄輔助.記錄(檔案編號, "預覽", IP, "成功", null, row["原始檔名"].ToString());
                context.Response.ContentType = "text/plain";
                context.Response.Write("ok");
                return;
            }

            string 路徑 = row["檔案路徑"].ToString();
            string 副檔名 = row["副檔名"].ToString().ToLower();
            string 原始檔名 = row["原始檔名"].ToString();

            if (!File.Exists(路徑)) { context.Response.StatusCode = 404; return; }

            操作紀錄輔助.記錄(檔案編號, "預覽", IP, "成功", null, 原始檔名);

            if (副檔名 == ".pdf")
            {
                context.Response.ContentType = "application/pdf";
                context.Response.AddHeader("Content-Disposition", "inline; filename*=UTF-8''" + Uri.EscapeDataString(原始檔名));
                context.Response.TransmitFile(路徑);
                return;
            }

            if (Array.Exists(圖片格式, ext => ext == 副檔名))
            {
                string contentType = 副檔名 == ".png" ? "image/png" :
                                     副檔名 == ".gif" ? "image/gif" : "image/jpeg";
                context.Response.ContentType = contentType;
                context.Response.TransmitFile(路徑);
                return;
            }

            if (Array.Exists(文字格式, ext => ext == 副檔名))
            {
                context.Response.ContentType = "text/html; charset=utf-8";
                string 內容 = File.ReadAllText(路徑, System.Text.Encoding.UTF8);
                var sb = new StringBuilder();
                sb.Append("<!DOCTYPE html>");
                sb.Append("<html><head><meta charset='utf-8'>");
                sb.Append("<style>");
                sb.Append("body{font-family:'Noto Sans TC',sans-serif;padding:20px;background:#f8f9fa;}");
                sb.Append("pre{background:white;padding:20px;border-radius:8px;overflow:auto;font-size:13px;line-height:1.6;box-shadow:0 2px 8px rgba(0,0,0,0.08);}");
                sb.Append("</style>");
                sb.Append("</head><body><h4 style='color:#1a3a6b;margin-bottom:12px;'>");
                sb.Append(HttpUtility.HtmlEncode(原始檔名));
                sb.Append("</h4>");
                sb.Append("<pre>");
                sb.Append(HttpUtility.HtmlEncode(內容));
                sb.Append("</pre></body></html>");
                context.Response.Write(sb.ToString());
                return;
            }

            context.Response.ContentType = "text/html; charset=utf-8";
            var sbError = new StringBuilder();
            sbError.Append("<html><body style='font-family:sans-serif;text-align:center;padding:50px;color:#6b7280;'>");
            sbError.Append("<i style='font-size:48px;'>📄</i><br/><br/>");
            sbError.Append("<p>此檔案格式不支援線上預覽</p>");
            sbError.Append("<a href='../Handlers/下載.ashx?id=");
            sbError.Append(檔案編號);
            sbError.Append("' style='color:#1a3a6b;'>點此下載</a>");
            sbError.Append("</body></html>");
            context.Response.Write(sbError.ToString());
        }
        catch (Exception ex)
        {
            例外處理輔助.記錄例外(ex, "預覽例外", "Handlers/預覽.ashx");
            context.Response.StatusCode = 500;
        }
    }

    public bool IsReusable { get { return false; } }
}
