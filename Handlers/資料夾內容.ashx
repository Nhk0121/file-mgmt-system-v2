<%@ WebHandler Language="C#" Class="資料夾內容Handler" %>
using System;
using System.Data;
using System.Text;
using System.Web;

/// <summary>
/// Ajax 取得資料夾內容 JSON
/// </summary>
public class 資料夾內容Handler : IHttpHandler
{
    public void ProcessRequest(HttpContext context)
    {
        try
        {
            context.Response.ContentType = "application/json";
            context.Response.ContentEncoding = Encoding.UTF8;

            if (!權限輔助.要求登入(context)) return;

            string fidStr = context.Request.QueryString["fid"];
            if (string.IsNullOrEmpty(fidStr))
            {
                context.Response.Write("{\"folders\":[],\"files\":[]}");
                return;
            }

            int fid = int.Parse(fidStr);
            var 資料夾資訊 = 資料夾輔助.取得資料夾資訊(fid);
            if (!權限輔助.可存取資料夾(資料夾資訊))
            {
                權限輔助.回應錯誤(context, 403, "沒有此資料夾的查看權限");
                return;
            }

            操作紀錄輔助.記錄(null, "預覽", IP輔助.取得用戶端IP(), "成功", null, null,
                "瀏覽資料夾:" + fid);

            var folders = 資料庫輔助.查詢(@"
            SELECT f.資料夾編號, f.資料夾名稱, f.儲存區類型, f.建立時間,
                   (SELECT COUNT(*) FROM 資料夾 c WHERE c.父資料夾編號=f.資料夾編號 AND c.是否刪除=0) +
                   (SELECT COUNT(*) FROM 檔案主檔 m WHERE m.資料夾編號=f.資料夾編號 AND m.是否刪除=0) AS 項目數
            FROM 資料夾 f
            WHERE f.父資料夾編號=@fid AND f.是否刪除=0
            ORDER BY f.資料夾名稱",
            資料庫輔助.P("@fid", fid));

            string 檔案條件 = "WHERE 資料夾編號=@fid AND 是否刪除=0";
            if (!角色輔助.是管理員())
            {
                if (角色輔助.是外包())
                    檔案條件 += " AND 儲存區類型='時效區'";
                else if (角色輔助.是本組負責人(Convert.ToInt32(資料夾資訊["組別編號"])))
                    檔案條件 += " AND (儲存區類型<>'永久區' OR 審核狀態 IN ('待審核','已通過'))";
                else
                    檔案條件 += " AND (儲存區類型<>'永久區' OR 審核狀態='已通過')";
            }

            var files = 資料庫輔助.查詢(string.Format(@"
            SELECT 檔案編號, 原始檔名, 副檔名, 檔案大小, 上傳時間, 儲存區類型, 審核狀態
            FROM 檔案主檔
            {0}
            ORDER BY 上傳時間 DESC", 檔案條件),
            資料庫輔助.P("@fid", fid));

            var sb = new StringBuilder();
            sb.Append("{\"folders\":[");
            for (int i = 0; i < folders.Rows.Count; i++)
            {
                if (i > 0) sb.Append(",");
                var r = folders.Rows[i];
                sb.AppendFormat("{{\"id\":{0},\"name\":{1},\"count\":{2},\"created\":\"{3}\"}}",
                    r["資料夾編號"],
                    JsonStr(r["資料夾名稱"].ToString()),
                    r["項目數"],
                    民國日期.轉換日期(Convert.ToDateTime(r["建立時間"])));
            }
            sb.Append("],\"files\":[");
            for (int i = 0; i < files.Rows.Count; i++)
            {
                if (i > 0) sb.Append(",");
                var r = files.Rows[i];
                long bytes = r["檔案大小"] == DBNull.Value ? 0 : Convert.ToInt64(r["檔案大小"]);
                string size = FormatSize(bytes);
                bool isPerm = r["儲存區類型"].ToString() == "永久區";
                sb.AppendFormat(
                    "{{\"id\":{0},\"name\":{1},\"ext\":{2},\"size\":\"{3}\",\"uploaded\":\"{4}\",\"permanent\":{5},\"審核\":{6}}}",
                    r["檔案編號"],
                    JsonStr(r["原始檔名"].ToString()),
                    JsonStr(r["副檔名"].ToString()),
                    size,
                    民國日期.轉換日期(Convert.ToDateTime(r["上傳時間"])),
                    isPerm ? "true" : "false",
                    JsonStr(r["審核狀態"].ToString()));
            }
            sb.Append("]}");

            context.Response.Write(sb.ToString());
        }
        catch (Exception ex)
        {
            例外處理輔助.記錄例外(ex, "資料夾內容例外", "Handlers/資料夾內容.ashx");
            權限輔助.回應錯誤(context, 500, "讀取資料夾內容失敗");
        }
    }

    private static string JsonStr(string s)
    {
        return "\"" + (s ?? "").Replace("\\", "\\\\").Replace("\"", "\\\"").Replace("\n", "\\n").Replace("\r", "") + "\"";
    }

    private static string FormatSize(long bytes)
    {
        if (bytes < 1024) return bytes + " B";
        if (bytes < 1024 * 1024) return string.Format("{0:F1} KB", bytes / 1024.0);
        return string.Format("{0:F1} MB", bytes / (1024.0 * 1024));
    }

    public bool IsReusable { get { return false; } }
}
