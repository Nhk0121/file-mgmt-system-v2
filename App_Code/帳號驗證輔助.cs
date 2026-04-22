using System;
using System.Data;
using System.Data.SqlClient;
using System.Security.Cryptography;
using System.Text;
using System.Web;

/// <summary>
/// 帳號驗證輔助類別 - 改進版
/// 功能：帳號登入驗證、Session 管理、帳號信息查詢
/// 改進點：使用帳號編號 + 密碼驗證，IP 作為輔助日誌
/// </summary>
public static class 帳號驗證輔助
{
    /// <summary>
    /// 驗證帳號與密碼
    /// </summary>
    public static bool 驗證帳號密碼(string 登入帳號, string 密碼, out int 帳號編號, out string 錯誤訊息)
    {
        帳號編號 = 0;
        錯誤訊息 = "";

        if (string.IsNullOrEmpty(登入帳號) || string.IsNullOrEmpty(密碼))
        {
            錯誤訊息 = "帳號或密碼不能為空";
            return false;
        }

        try
        {
            // 查詢帳號
            var dt = 資料庫輔助.查詢(
                "SELECT 帳號編號, 密碼, 密碼Salt, 角色, 組別編號, 是否啟用, 是否鎖定 FROM 使用者帳號 WHERE 登入帳號=@帳號",
                資料庫輔助.P("@帳號", 登入帳號));

            if (dt.Rows.Count == 0)
            {
                錯誤訊息 = "帳號不存在";
                return false;
            }

            var row = dt.Rows[0];
            帳號編號 = Convert.ToInt32(row["帳號編號"]);

            // 檢查帳號狀態
            if (Convert.ToBoolean(row["是否鎖定"]))
            {
                錯誤訊息 = "帳號已被鎖定，請聯絡管理員";
                return false;
            }

            if (!Convert.ToBoolean(row["是否啟用"]))
            {
                錯誤訊息 = "帳號已被停用";
                return false;
            }

            // 驗證密碼
            string 儲存密碼 = row["密碼"].ToString();
            string Salt = row["密碼Salt"].ToString();
            string 計算密碼 = 計算密碼雜湊(密碼, Salt);

            if (儲存密碼 != 計算密碼)
            {
                // 記錄登入失敗
                記錄登入失敗(帳號編號, 登入帳號);
                錯誤訊息 = "密碼錯誤";
                return false;
            }

            // 登入成功，清除失敗計數
            清除登入失敗計數(帳號編號);
            return true;
        }
        catch (Exception ex)
        {
            錯誤訊息 = "驗證過程出錯：" + ex.Message;
            return false;
        }
    }

    /// <summary>
    /// 建立 Session 資訊
    /// </summary>
    public static void 建立Session(int 帳號編號)
    {
        try
        {
            var dt = 資料庫輔助.查詢(
                @"SELECT 帳號編號, 登入帳號, 姓名, 角色, 組別編號, 課別, 分機
                  FROM 使用者帳號 WHERE 帳號編號=@編號",
                資料庫輔助.P("@編號", 帳號編號));

            if (dt.Rows.Count > 0)
            {
                var row = dt.Rows[0];
                HttpContext.Current.Session["帳號編號"] = 帳號編號;
                HttpContext.Current.Session["登入帳號"] = row["登入帳號"].ToString();
                HttpContext.Current.Session["姓名"] = row["姓名"].ToString();
                HttpContext.Current.Session["角色"] = row["角色"].ToString();
                HttpContext.Current.Session["組別編號"] = Convert.ToInt32(row["組別編號"]);
                HttpContext.Current.Session["課別"] = row["課別"].ToString();
                HttpContext.Current.Session["分機"] = row["分機"].ToString();
                HttpContext.Current.Session["已登入"] = true;
                HttpContext.Current.Session["登入時間"] = DateTime.Now;
                HttpContext.Current.Session.Timeout = 30; // 30 分鐘超時

                // 記錄登入
                記錄登入成功(帳號編號, row["登入帳號"].ToString());
            }
        }
        catch (Exception ex)
        {
            throw new Exception("建立 Session 失敗：" + ex.Message);
        }
    }

    /// <summary>
    /// 驗證 Session 有效性
    /// </summary>
    public static bool 驗證Session有效()
    {
        if (HttpContext.Current.Session["帳號編號"] == null)
            return false;

        try
        {
            int 帳號編號 = Convert.ToInt32(HttpContext.Current.Session["帳號編號"]);
            
            // 檢查帳號是否仍然啟用
            var dt = 資料庫輔助.查詢(
                "SELECT 是否啟用, 是否鎖定 FROM 使用者帳號 WHERE 帳號編號=@編號",
                資料庫輔助.P("@編號", 帳號編號));

            if (dt.Rows.Count == 0)
                return false;

            bool 是否啟用 = Convert.ToBoolean(dt.Rows[0]["是否啟用"]);
            bool 是否鎖定 = Convert.ToBoolean(dt.Rows[0]["是否鎖定"]);

            return 是否啟用 && !是否鎖定;
        }
        catch
        {
            return false;
        }
    }

    /// <summary>
    /// 取得目前登入帳號編號
    /// </summary>
    public static int 取得帳號編號()
    {
        if (HttpContext.Current.Session["帳號編號"] != null)
            return Convert.ToInt32(HttpContext.Current.Session["帳號編號"]);
        return 0;
    }

    /// <summary>
    /// 取得目前登入帳號的角色
    /// </summary>
    public static string 取得角色()
    {
        if (HttpContext.Current.Session["角色"] != null)
            return HttpContext.Current.Session["角色"].ToString();
        return "";
    }

    /// <summary>
    /// 取得目前登入帳號的組別編號
    /// </summary>
    public static int 取得組別編號()
    {
        if (HttpContext.Current.Session["組別編號"] != null)
            return Convert.ToInt32(HttpContext.Current.Session["組別編號"]);
        return 0;
    }

    /// <summary>
    /// 登出
    /// </summary>
    public static void 登出()
    {
        if (HttpContext.Current.Session["帳號編號"] != null)
        {
            int 帳號編號 = Convert.ToInt32(HttpContext.Current.Session["帳號編號"]);
            記錄登出(帳號編號);
        }
        HttpContext.Current.Session.Clear();
        HttpContext.Current.Session.Abandon();
    }

    /// <summary>
    /// 修改密碼
    /// </summary>
    public static bool 修改密碼(int 帳號編號, string 舊密碼, string 新密碼, out string 錯誤訊息)
    {
        錯誤訊息 = "";

        if (string.IsNullOrEmpty(舊密碼) || string.IsNullOrEmpty(新密碼))
        {
            錯誤訊息 = "舊密碼和新密碼不能為空";
            return false;
        }

        if (新密碼.Length < 6)
        {
            錯誤訊息 = "新密碼至少需要 6 個字元";
            return false;
        }

        try
        {
            // 驗證舊密碼
            var dt = 資料庫輔助.查詢(
                "SELECT 密碼, 密碼Salt FROM 使用者帳號 WHERE 帳號編號=@編號",
                資料庫輔助.P("@編號", 帳號編號));

            if (dt.Rows.Count == 0)
            {
                錯誤訊息 = "帳號不存在";
                return false;
            }

            string 儲存密碼 = dt.Rows[0]["密碼"].ToString();
            string Salt = dt.Rows[0]["密碼Salt"].ToString();
            string 計算密碼 = 計算密碼雜湊(舊密碼, Salt);

            if (儲存密碼 != 計算密碼)
            {
                錯誤訊息 = "舊密碼錯誤";
                return false;
            }

            // 生成新 Salt 並計算新密碼
            string 新Salt = 生成Salt();
            string 新密碼雜湊 = 計算密碼雜湊(新密碼, 新Salt);

            // 更新密碼
            資料庫輔助.執行(
                "UPDATE 使用者帳號 SET 密碼=@密碼, 密碼Salt=@Salt, 密碼修改時間=GETDATE() WHERE 帳號編號=@編號",
                資料庫輔助.P("@密碼", 新密碼雜湊),
                資料庫輔助.P("@Salt", 新Salt),
                資料庫輔助.P("@編號", 帳號編號));

            // 記錄操作
            操作紀錄輔助.記錄(null, "修改密碼", IP輔助.取得用戶端IP(), "成功", null, null,
                string.Format("帳號編號 {0} 修改密碼", 帳號編號));

            return true;
        }
        catch (Exception ex)
        {
            錯誤訊息 = "修改密碼過程出錯：" + ex.Message;
            return false;
        }
    }

    /// <summary>
    /// 重設密碼（超管操作）
    /// </summary>
    public static bool 重設密碼(int 帳號編號, string 新密碼, out string 錯誤訊息)
    {
        錯誤訊息 = "";

        if (string.IsNullOrEmpty(新密碼))
        {
            錯誤訊息 = "新密碼不能為空";
            return false;
        }

        if (新密碼.Length < 6)
        {
            錯誤訊息 = "新密碼至少需要 6 個字元";
            return false;
        }

        try
        {
            // 生成 Salt 並計算新密碼
            string Salt = 生成Salt();
            string 密碼雜湊 = 計算密碼雜湊(新密碼, Salt);

            // 更新密碼
            資料庫輔助.執行(
                "UPDATE 使用者帳號 SET 密碼=@密碼, 密碼Salt=@Salt, 密碼修改時間=GETDATE() WHERE 帳號編號=@編號",
                資料庫輔助.P("@密碼", 密碼雜湊),
                資料庫輔助.P("@Salt", Salt),
                資料庫輔助.P("@編號", 帳號編號));

            // 記錄操作
            操作紀錄輔助.記錄(null, "重設密碼", IP輔助.取得用戶端IP(), "成功", null, null,
                string.Format("帳號編號 {0} 密碼已重設", 帳號編號));

            return true;
        }
        catch (Exception ex)
        {
            錯誤訊息 = "重設密碼過程出錯：" + ex.Message;
            return false;
        }
    }

    // ── 私有方法 ──────────────────────────────────────────

    /// <summary>
    /// 生成隨機 Salt
    /// </summary>
    private static string 生成Salt()
    {
        using (var rng = new RNGCryptoServiceProvider())
        {
            byte[] tokenBuffer = new byte[16];
            rng.GetBytes(tokenBuffer);
            return Convert.ToBase64String(tokenBuffer);
        }
    }

    /// <summary>
    /// 計算密碼雜湊
    /// </summary>
    private static string 計算密碼雜湊(string 密碼, string Salt)
    {
        using (var sha256 = SHA256.Create())
        {
            byte[] saltBytes = Encoding.UTF8.GetBytes(Salt);
            byte[] passwordBytes = Encoding.UTF8.GetBytes(密碼);
            byte[] combined = new byte[saltBytes.Length + passwordBytes.Length];
            Buffer.BlockCopy(saltBytes, 0, combined, 0, saltBytes.Length);
            Buffer.BlockCopy(passwordBytes, 0, combined, saltBytes.Length, passwordBytes.Length);
            byte[] hash = sha256.ComputeHash(combined);
            return Convert.ToBase64String(hash);
        }
    }

    /// <summary>
    /// 記錄登入成功
    /// </summary>
    private static void 記錄登入成功(int 帳號編號, string 登入帳號)
    {
        try
        {
            string IP = IP輔助.取得用戶端IP();
            資料庫輔助.執行(
                @"UPDATE 使用者帳號 SET 最後登入時間=GETDATE(), 最後登入IP=@IP 
                  WHERE 帳號編號=@編號",
                資料庫輔助.P("@IP", IP),
                資料庫輔助.P("@編號", 帳號編號));

            操作紀錄輔助.記錄(null, "登入", IP, "成功", null, null,
                string.Format("帳號 {0} 登入成功", 登入帳號));
        }
        catch { }
    }

    /// <summary>
    /// 記錄登入失敗
    /// </summary>
    private static void 記錄登入失敗(int 帳號編號, string 登入帳號)
    {
        try
        {
            string IP = IP輔助.取得用戶端IP();
            
            // 更新失敗計數
            資料庫輔助.執行(
                @"UPDATE 使用者帳號 SET 登入失敗次數=ISNULL(登入失敗次數,0)+1,
                  最後登入失敗時間=GETDATE()
                  WHERE 帳號編號=@編號",
                資料庫輔助.P("@編號", 帳號編號));

            // 如果失敗次數超過 5，鎖定帳號
            var dt = 資料庫輔助.查詢(
                "SELECT 登入失敗次數 FROM 使用者帳號 WHERE 帳號編號=@編號",
                資料庫輔助.P("@編號", 帳號編號));

            if (dt.Rows.Count > 0 && Convert.ToInt32(dt.Rows[0]["登入失敗次數"]) >= 5)
            {
                資料庫輔助.執行(
                    "UPDATE 使用者帳號 SET 是否鎖定=1 WHERE 帳號編號=@編號",
                    資料庫輔助.P("@編號", 帳號編號));

                操作紀錄輔助.資安警示("帳號鎖定", "高", IP,
                    string.Format("帳號 {0}", 登入帳號),
                    "登入失敗次數超過 5 次，帳號已自動鎖定");
            }

            操作紀錄輔助.記錄(null, "登入失敗", IP, "失敗", null, null,
                string.Format("帳號 {0} 登入失敗", 登入帳號));
        }
        catch { }
    }

    /// <summary>
    /// 清除登入失敗計數
    /// </summary>
    private static void 清除登入失敗計數(int 帳號編號)
    {
        try
        {
            資料庫輔助.執行(
                "UPDATE 使用者帳號 SET 登入失敗次數=0 WHERE 帳號編號=@編號",
                資料庫輔助.P("@編號", 帳號編號));
        }
        catch { }
    }

    /// <summary>
    /// 記錄登出
    /// </summary>
    private static void 記錄登出(int 帳號編號)
    {
        try
        {
            操作紀錄輔助.記錄(null, "登出", IP輔助.取得用戶端IP(), "成功", null, null,
                "帳號登出");
        }
        catch { }
    }
}
