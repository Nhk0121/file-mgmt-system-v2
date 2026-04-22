<%@ WebHandler Language="C#" Class="上傳Handler" %>
using System;
using System.IO;
using System.Web;

/// <summary>
/// Ajax 上傳 Handler — 接收拖放或直接上傳的檔案
/// POST 參數：fid (資料夾編號)
/// </summary>
public class 上傳Handler : IHttpHandler
{
    private static readonly string[] 危險副檔名 = { ".exe", ".bat", ".cmd", ".com", ".ps1", ".vbs", ".sh", ".msi", ".dll", ".scr" };

    public void ProcessRequest(HttpContext context)
    {
        context.Response.ContentType = "application/json";
        context.Response.ContentEncoding = System.Text.Encoding.UTF8;

        if (!權限輔助.要求登入(context)) return;

        string IP = IP輔助.取得用戶端IP();

        try
        {
            string fidStr = context.Request.Form["fid"];
            if (string.IsNullOrEmpty(fidStr))
            {
                context.Response.Write("{\"ok\":false,\"msg\":\"請先選擇目標資料夾\"}");
                return;
            }

            int fid = int.Parse(fidStr);
            var 資料夾info = 資料夾輔助.取得資料夾資訊(fid);
            if (資料夾info == null)
            {
                context.Response.Write("{\"ok\":false,\"msg\":\"資料夾不存在\"}");
                return;
            }
            if (!權限輔助.可存取資料夾(資料夾info, true))
            {
                操作紀錄輔助.記錄(null, "上傳", IP, "失敗", "無上傳權限", null, "資料夾 " + fid);
                權限輔助.回應錯誤(context, 403, "沒有此資料夾的上傳權限");
                return;
            }

            if (context.Request.Files.Count == 0)
            {
                context.Response.Write("{\"ok\":false,\"msg\":\"未收到檔案\"}");
                return;
            }

            var file = context.Request.Files[0];
            string 原始檔名 = Path.GetFileName(file.FileName);
            string 副檔名 = Path.GetExtension(原始檔名).ToLower();

            string 驗證訊息;
            if (!檔案安全輔助.驗證上傳檔案(file, IP, out 驗證訊息))
            {
                操作紀錄輔助.記錄(null, "上傳", IP, "拒絕", 驗證訊息, 原始檔名);
                if (驗證訊息.Contains("執行檔") || 驗證訊息.Contains("偽裝") || 驗證訊息.Contains("不符"))
                    操作紀錄輔助.資安警示("可疑上傳", "高", IP, 原始檔名, 驗證訊息);
                context.Response.Write("{\"ok\":false,\"msg\":\"" + HttpUtility.JavaScriptStringEncode(驗證訊息) + "\"}");
                return;
            }

            bool 是執行檔 = Array.Exists(危險副檔名, ext => ext == 副檔名);
            if (是執行檔 && !IP輔助.可上傳執行檔(IP))
            {
                操作紀錄輔助.資安警示("未授權執行檔上傳", "高", IP, 原始檔名, "嘗試上傳未授權執行檔");
                context.Response.Write("{\"ok\":false,\"msg\":\"此IP不允許上傳執行檔\"}");
                return;
            }

            int 最大MB = 設定輔助.取得整數("最大上傳檔案大小MB", 500, "最大上傳MB");
            if (file.ContentLength > 最大MB * 1024 * 1024)
            {
                context.Response.Write("{\"ok\":false,\"msg\":\"\u6a94\u6848\u8d85\u904e " + 最大MB + "MB \u9650\u5236\"}");
                return;
            }

            int 組別編號 = Convert.ToInt32(資料夾info["組別編號"]);
            string 儲存區類型 = 資料夾info["儲存區類型"].ToString();
            string 實體路徑 = 資料夾info["實體路徑"].ToString();
            Directory.CreateDirectory(實體路徑);

            string 唯一檔名 = string.Format("{0:yyyyMMddHHmmss}_{1:N}{2}", DateTime.Now, Guid.NewGuid(), 副檔名);
            string 完整路徑 = Path.Combine(實體路徑, 唯一檔名);
            file.SaveAs(完整路徑);

            DateTime? 到期時間 = null;
            if (儲存區類型 == "時效區")
            {
                int 天數 = 設定輔助.取得整數("時效區保存天數", 30, "時效區天數");
                到期時間 = DateTime.Now.AddDays(天數);
            }

            string 審核狀態 = 儲存區類型 == "永久區" ? "待審核" : "不需審核";

            object result = 資料庫輔助.查詢單值(@"
                INSERT INTO 檔案主檔
                    (組別編號,資料夾編號,儲存區類型,原始檔名,儲存檔名,檔案路徑,
                     檔案大小,檔案類型,副檔名,上傳者IP,到期時間,審核狀態)
                VALUES
                    (@組別,@資料夾,@儲存區,@原始,@儲存,@路徑,
                     @大小,@類型,@副檔名,@IP,@到期,@狀態);
                SELECT SCOPE_IDENTITY();",
                資料庫輔助.P("@組別",  組別編號),
                資料庫輔助.P("@資料夾", fid),
                資料庫輔助.P("@儲存區", 儲存區類型),
                資料庫輔助.P("@原始",  原始檔名),
                資料庫輔助.P("@儲存",  唯一檔名),
                資料庫輔助.P("@路徑",  完整路徑),
                資料庫輔助.P("@大小",  file.ContentLength),
                資料庫輔助.P("@類型",  file.ContentType),
                資料庫輔助.P("@副檔名", 副檔名),
                資料庫輔助.P("@IP",    IP),
                資料庫輔助.P("@到期",  (object)到期時間 ?? DBNull.Value),
                資料庫輔助.P("@狀態",  審核狀態));

            int 新id = Convert.ToInt32(result);

            // 個資偵測
            string 個資風險 = 個資偵測.掃描檔名(原始檔名);
            if (!string.IsNullOrEmpty(個資風險))
                資料庫輔助.執行(@"INSERT INTO 個資稽核紀錄 (檔案編號,偵測類型,偵測內容,操作者IP,操作類型,風險等級)
                    VALUES (@編號,'檔名個資偵測',@內容,@IP,'上傳','中')",
                    資料庫輔助.P("@編號", 新id),
                    資料庫輔助.P("@內容", string.Format("{0}: {1}", 原始檔名, 個資風險)),
                    資料庫輔助.P("@IP",   IP));

            操作紀錄輔助.記錄(新id, "上傳", IP, "成功", null, 原始檔名, 儲存區類型);

            context.Response.Write(
                "{\"ok\":true,\"id\":" + 新id + ",\"name\":\"" + 原始檔名.Replace("\"", "\\\"") + "\",\"msg\":\"" +
                (審核狀態 == "待審核" ? "上傳成功，待審核" : "上傳成功") + "\"}");
        }
        catch (Exception ex)
        {
            例外處理輔助.記錄例外(ex, "上傳例外", "Handlers/上傳.ashx");
            context.Response.Write("{\"ok\":false,\"msg\":\"" + ex.Message.Replace("\"", "'") + "\"}" );
        }
    }

    public bool IsReusable { get { return false; } }
}
