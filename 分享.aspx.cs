using System;
using System.Data;
using System.IO;
using System.Web;

/// <summary>
/// 檔案分享連結下載功能
/// 功能：
/// 1. 生成分享連結（支援有效期、密碼、下載次數限制）
/// 2. 透過分享連結下載檔案（無需登入）
/// 3. 記錄分享連結的下載統計
/// </summary>
public partial class 分享 : System.Web.UI.Page
{
    protected void Page_Load(object sender, EventArgs e)
    {
        string 連結代碼 = Request.QueryString["code"];

        if (string.IsNullOrEmpty(連結代碼))
        {
            Response.Write("分享連結無效");
            Response.End();
            return;
        }

        // 查詢分享連結
        DataTable dt = 資料庫輔助.查詢(
            @"SELECT * FROM 檔案分享連結 
              WHERE 分享連結=@連結 AND 是否啟用=1",
            資料庫輔助.P("@連結", 連結代碼)
        );

        if (dt.Rows.Count == 0)
        {
            Response.Write("分享連結不存在或已過期");
            Response.End();
            return;
        }

        DataRow 分享 = dt.Rows[0];

        // 檢查連結是否過期
        if (分享["到期時間"] != DBNull.Value)
        {
            DateTime 到期時間 = Convert.ToDateTime(分享["到期時間"]);
            if (DateTime.Now > 到期時間)
            {
                Response.Write("分享連結已過期");
                Response.End();
                return;
            }
        }

        // 檢查下載次數限制
        if (分享["最大下載次數"] != DBNull.Value)
        {
            int 最大下載次數 = Convert.ToInt32(分享["最大下載次數"]);
            int 下載次數 = Convert.ToInt32(分享["下載次數"]);

            if (下載次數 >= 最大下載次數)
            {
                Response.Write("分享連結的下載次數已達上限");
                Response.End();
                return;
            }
        }

        // 檢查密碼
        if (!string.IsNullOrEmpty(分享["密碼"].ToString()))
        {
            string 輸入密碼 = Request.QueryString["pwd"];
            string 儲存密碼 = 分享["密碼"].ToString();

            if (string.IsNullOrEmpty(輸入密碼) || !驗證密碼(輸入密碼, 儲存密碼))
            {
                Response.Write("分享連結密碼錯誤");
                Response.End();
                return;
            }
        }

        // 查詢檔案資訊
        int 檔案編號 = Convert.ToInt32(分享["檔案編號"]);
        DataTable dtFile = 資料庫輔助.查詢(
            "SELECT * FROM 檔案主檔 WHERE 檔案編號=@編號",
            資料庫輔助.P("@編號", 檔案編號)
        );

        if (dtFile.Rows.Count == 0 || Convert.ToBoolean(dtFile.Rows[0]["是否刪除"]))
        {
            Response.Write("檔案不存在或已刪除");
            Response.End();
            return;
        }

        DataRow 檔案 = dtFile.Rows[0];
        string 檔案路徑 = 檔案["檔案路徑"].ToString();
        string 檔案名稱 = 檔案["原始檔名"].ToString();

        // 檢查檔案是否存在
        if (!File.Exists(檔案路徑))
        {
            Response.Write("檔案不存在於磁碟");
            Response.End();
            return;
        }

        try
        {
            // 更新下載次數
            資料庫輔助.執行(
                @"UPDATE 檔案分享連結 
                  SET 下載次數=下載次數+1 
                  WHERE 分享編號=@編號",
                資料庫輔助.P("@編號", 分享["分享編號"])
            );

            // 記錄下載
            操作紀錄輔助.記錄(檔案編號, "分享下載", IP輔助.取得用戶端IP(), "成功", null, null,
                string.Format("透過分享連結下載: 連結代碼={0}", 連結代碼));

            // 執行下載
            Response.ContentType = "application/octet-stream";
            Response.AddHeader("Content-Disposition", "attachment; filename=" + HttpUtility.UrlEncode(檔案名稱));
            Response.WriteFile(檔案路徑);
            Response.End();
        }
        catch (Exception ex)
        {
            Response.Write("下載失敗：" + ex.Message);
            Response.End();
        }
    }

    /// <summary>
    /// 驗證密碼
    /// </summary>
    private bool 驗證密碼(string 輸入密碼, string 儲存密碼)
    {
        // 簡單實現，實際應使用加密比對
        return 輸入密碼 == 儲存密碼;
    }
}

/// <summary>
/// 檔案分享連結管理 - 在檔案瀏覽頁面中使用
/// </summary>
public static class 分享連結輔助
{
    /// <summary>
    /// 生成分享連結
    /// </summary>
    public static string 生成分享連結(int 檔案編號, int 有效期天數 = 7, string 密碼 = "", int 最大下載次數 = 0)
    {
        try
        {
            // 生成唯一的分享連結代碼
            string 分享連結 = Guid.NewGuid().ToString().Replace("-", "").Substring(0, 16);

            DateTime 到期時間 = 有效期天數 > 0 ? DateTime.Now.AddDays(有效期天數) : DateTime.MaxValue;

            資料庫輔助.執行(
                @"INSERT INTO 檔案分享連結 (檔案編號, 分享連結, 分享者帳號, 到期時間, 最大下載次數, 密碼, 是否啟用)
                  VALUES (@檔案, @連結, @帳號, @到期, @次數, @密碼, 1)",
                資料庫輔助.P("@檔案", 檔案編號),
                資料庫輔助.P("@連結", 分享連結),
                資料庫輔助.P("@帳號", System.Web.HttpContext.Current.Session["登入帳號"].ToString()),
                資料庫輔助.P("@到期", 到期時間),
                資料庫輔助.P("@次數", 最大下載次數 > 0 ? 最大下載次數 : (object)DBNull.Value),
                資料庫輔助.P("@密碼", string.IsNullOrEmpty(密碼) ? (object)DBNull.Value : 密碼)
            );

            return 分享連結;
        }
        catch (Exception ex)
        {
            throw new Exception("生成分享連結失敗：" + ex.Message);
        }
    }

    /// <summary>
    /// 取得分享連結完整 URL
    /// </summary>
    public static string 取得分享連結URL(string 分享連結, string 密碼 = "")
    {
        string 基礎URL = System.Web.HttpContext.Current.Request.Url.Scheme + "://" +
                        System.Web.HttpContext.Current.Request.Url.Authority + "/分享.aspx?code=" + 分享連結;

        if (!string.IsNullOrEmpty(密碼))
            基礎URL += "&pwd=" + System.Web.HttpUtility.UrlEncode(密碼);

        return 基礎URL;
    }

    /// <summary>
    /// 停用分享連結
    /// </summary>
    public static void 停用分享連結(string 分享連結)
    {
        try
        {
            資料庫輔助.執行(
                @"UPDATE 檔案分享連結 
                  SET 是否啟用=0 
                  WHERE 分享連結=@連結",
                資料庫輔助.P("@連結", 分享連結)
            );
        }
        catch (Exception ex)
        {
            throw new Exception("停用分享連結失敗：" + ex.Message);
        }
    }

    /// <summary>
    /// 取得分享連結清單
    /// </summary>
    public static DataTable 取得分享連結清單(int 檔案編號)
    {
        try
        {
            return 資料庫輔助.查詢(
                @"SELECT 分享編號, 分享連結, 分享時間, 到期時間, 下載次數, 最大下載次數, 是否啟用,
                         CASE WHEN 到期時間 < GETDATE() THEN N'已過期' 
                              WHEN 是否啟用=0 THEN N'已停用'
                              WHEN 最大下載次數 > 0 AND 下載次數 >= 最大下載次數 THEN N'已達上限'
                              ELSE N'有效' END AS 狀態
                  FROM 檔案分享連結
                  WHERE 檔案編號=@檔案
                  ORDER BY 分享時間 DESC",
                資料庫輔助.P("@檔案", 檔案編號)
            );
        }
        catch (Exception ex)
        {
            throw new Exception("取得分享連結清單失敗：" + ex.Message);
        }
    }
}
