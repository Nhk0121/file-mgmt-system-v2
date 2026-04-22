using System;
using System.Data;
using System.Web;

/// <summary>
/// 檔案權限驗證輔助類別 - 改進版
/// 功能：檔案下載權限驗證、檔案存取控制
/// 改進點：新增完整的下載權限檢查機制
/// </summary>
public static class 檔案權限輔助
{
    /// <summary>
    /// 驗證使用者是否可以下載檔案
    /// </summary>
    public static bool 可下載檔案(int 檔案編號, int 帳號編號, out string 錯誤訊息)
    {
        錯誤訊息 = "";

        try
        {
            // 1. 驗證檔案是否存在且未被刪除
            var 檔案dt = 資料庫輔助.查詢(
                @"SELECT f.檔案編號, f.資料夾編號, f.組別編號, f.儲存區類型, 
                         f.審核狀態, f.到期時間, f.是否刪除, f.檔案路徑
                  FROM 檔案主檔 f
                  WHERE f.檔案編號=@檔案編號",
                資料庫輔助.P("@檔案編號", 檔案編號));

            if (檔案dt.Rows.Count == 0)
            {
                錯誤訊息 = "檔案不存在";
                return false;
            }

            var 檔案row = 檔案dt.Rows[0];

            // 2. 檢查檔案是否已被刪除
            if (Convert.ToBoolean(檔案row["是否刪除"]))
            {
                錯誤訊息 = "檔案已被刪除";
                return false;
            }

            // 3. 取得帳號資訊
            var 帳號dt = 資料庫輔助.查詢(
                "SELECT 角色, 組別編號 FROM 使用者帳號 WHERE 帳號編號=@編號",
                資料庫輔助.P("@編號", 帳號編號));

            if (帳號dt.Rows.Count == 0)
            {
                錯誤訊息 = "帳號不存在";
                return false;
            }

            string 角色 = 帳號dt.Rows[0]["角色"].ToString();
            int 帳號組別 = Convert.ToInt32(帳號dt.Rows[0]["組別編號"]);
            int 檔案組別 = Convert.ToInt32(檔案row["組別編號"]);
            int? 資料夾編號 = 檔案row["資料夾編號"] == DBNull.Value ? (int?)null : Convert.ToInt32(檔案row["資料夾編號"]);

            // 4. 檢查組別權限
            if (角色 != "超管" && 帳號組別 != 檔案組別)
            {
                錯誤訊息 = "無權限下載其他組別的檔案";
                return false;
            }

            // 5. 檢查資料夾存取權限
            if (資料夾編號.HasValue)
            {
                if (!權限輔助.可存取資料夾(資料夾編號.Value, 帳號編號))
                {
                    錯誤訊息 = "無權限存取該資料夾";
                    return false;
                }
            }

            // 6. 檢查儲存區類型與審核狀態
            string 儲存區 = 檔案row["儲存區類型"].ToString();
            string 審核狀態 = 檔案row["審核狀態"].ToString();

            // 外包用戶只能下載時效區
            if (角色 == "外包" && 儲存區 != "時效區")
            {
                錯誤訊息 = "外包用戶只能下載時效區的檔案";
                return false;
            }

            // 永久區檔案必須已審核通過
            if (儲存區 == "永久區" && 審核狀態 != "已通過")
            {
                // 除非是超管或本組負責人
                if (角色 != "超管" && !是本組負責人(帳號編號, 檔案組別))
                {
                    錯誤訊息 = "該檔案尚未通過審核";
                    return false;
                }
            }

            // 7. 檢查時效區檔案是否已過期
            if (儲存區 == "時效區")
            {
                DateTime 到期時間 = Convert.ToDateTime(檔案row["到期時間"]);
                if (DateTime.Now > 到期時間)
                {
                    錯誤訊息 = "檔案已過期";
                    return false;
                }
            }

            // 8. 檢查檔案是否存在於磁碟
            string 檔案路徑 = 檔案row["檔案路徑"].ToString();
            if (!System.IO.File.Exists(檔案路徑))
            {
                錯誤訊息 = "檔案在磁碟上不存在";
                操作紀錄輔助.資安警示("檔案遺失", "高", IP輔助.取得用戶端IP(),
                    檔案編號.ToString(), string.Format("檔案 {0} 在磁碟上不存在", 檔案路徑));
                return false;
            }

            return true;
        }
        catch (Exception ex)
        {
            錯誤訊息 = "驗證過程出錯：" + ex.Message;
            return false;
        }
    }

    /// <summary>
    /// 驗證使用者是否可以上傳檔案到指定資料夾
    /// </summary>
    public static bool 可上傳檔案(int 資料夾編號, int 帳號編號, out string 錯誤訊息)
    {
        錯誤訊息 = "";

        try
        {
            // 取得資料夾資訊
            var 資料夾dt = 資料庫輔助.查詢(
                "SELECT 組別編號, 儲存區類型 FROM 資料夾 WHERE 資料夾編號=@編號 AND 是否刪除=0",
                資料庫輔助.P("@編號", 資料夾編號));

            if (資料夾dt.Rows.Count == 0)
            {
                錯誤訊息 = "資料夾不存在";
                return false;
            }

            int 資料夾組別 = Convert.ToInt32(資料夾dt.Rows[0]["組別編號"]);
            string 儲存區 = 資料夾dt.Rows[0]["儲存區類型"].ToString();

            // 取得帳號資訊
            var 帳號dt = 資料庫輔助.查詢(
                "SELECT 角色, 組別編號 FROM 使用者帳號 WHERE 帳號編號=@編號",
                資料庫輔助.P("@編號", 帳號編號));

            if (帳號dt.Rows.Count == 0)
            {
                錯誤訊息 = "帳號不存在";
                return false;
            }

            string 角色 = 帳號dt.Rows[0]["角色"].ToString();
            int 帳號組別 = Convert.ToInt32(帳號dt.Rows[0]["組別編號"]);

            // 超管可上傳到任何地方
            if (角色 == "超管")
                return true;

            // 非超管只能上傳到自己組別
            if (帳號組別 != 資料夾組別)
            {
                錯誤訊息 = "只能上傳檔案到自己組別的資料夾";
                return false;
            }

            // 外包用戶只能上傳到時效區
            if (角色 == "外包" && 儲存區 != "時效區")
            {
                錯誤訊息 = "外包用戶只能上傳檔案到時效區";
                return false;
            }

            return true;
        }
        catch (Exception ex)
        {
            錯誤訊息 = "驗證過程出錯：" + ex.Message;
            return false;
        }
    }

    /// <summary>
    /// 驗證使用者是否可以刪除檔案
    /// </summary>
    public static bool 可刪除檔案(int 檔案編號, int 帳號編號, out string 錯誤訊息)
    {
        錯誤訊息 = "";

        try
        {
            // 取得檔案資訊
            var 檔案dt = 資料庫輔助.查詢(
                "SELECT 組別編號, 上傳者IP FROM 檔案主檔 WHERE 檔案編號=@編號 AND 是否刪除=0",
                資料庫輔助.P("@編號", 檔案編號));

            if (檔案dt.Rows.Count == 0)
            {
                錯誤訊息 = "檔案不存在";
                return false;
            }

            int 檔案組別 = Convert.ToInt32(檔案dt.Rows[0]["組別編號"]);
            string 上傳者IP = 檔案dt.Rows[0]["上傳者IP"].ToString();

            // 取得帳號資訊
            var 帳號dt = 資料庫輔助.查詢(
                "SELECT 角色, 組別編號, 最後登入IP FROM 使用者帳號 WHERE 帳號編號=@編號",
                資料庫輔助.P("@編號", 帳號編號));

            if (帳號dt.Rows.Count == 0)
            {
                錯誤訊息 = "帳號不存在";
                return false;
            }

            string 角色 = 帳號dt.Rows[0]["角色"].ToString();
            int 帳號組別 = Convert.ToInt32(帳號dt.Rows[0]["組別編號"]);
            string 帳號IP = 帳號dt.Rows[0]["最後登入IP"].ToString();

            // 超管可刪除任何檔案
            if (角色 == "超管")
                return true;

            // 本組負責人可刪除本組檔案
            if (角色 == "負責人" && 帳號組別 == 檔案組別)
                return true;

            // 上傳者可刪除自己上傳的檔案
            if (帳號IP == 上傳者IP)
                return true;

            錯誤訊息 = "無權限刪除該檔案";
            return false;
        }
        catch (Exception ex)
        {
            錯誤訊息 = "驗證過程出錯：" + ex.Message;
            return false;
        }
    }

    /// <summary>
    /// 驗證使用者是否可以審核檔案
    /// </summary>
    public static bool 可審核檔案(int 檔案編號, int 帳號編號, out string 錯誤訊息)
    {
        錯誤訊息 = "";

        try
        {
            // 取得檔案資訊
            var 檔案dt = 資料庫輔助.查詢(
                "SELECT 組別編號 FROM 檔案主檔 WHERE 檔案編號=@編號 AND 是否刪除=0",
                資料庫輔助.P("@編號", 檔案編號));

            if (檔案dt.Rows.Count == 0)
            {
                錯誤訊息 = "檔案不存在";
                return false;
            }

            int 檔案組別 = Convert.ToInt32(檔案dt.Rows[0]["組別編號"]);

            // 取得帳號資訊
            var 帳號dt = 資料庫輔助.查詢(
                "SELECT 角色, 組別編號 FROM 使用者帳號 WHERE 帳號編號=@編號",
                資料庫輔助.P("@編號", 帳號編號));

            if (帳號dt.Rows.Count == 0)
            {
                錯誤訊息 = "帳號不存在";
                return false;
            }

            string 角色 = 帳號dt.Rows[0]["角色"].ToString();
            int 帳號組別 = Convert.ToInt32(帳號dt.Rows[0]["組別編號"]);

            // 超管可審核任何檔案
            if (角色 == "超管")
                return true;

            // 本組負責人可審核本組檔案
            if (角色 == "負責人" && 帳號組別 == 檔案組別)
                return true;

            錯誤訊息 = "無權限審核該檔案";
            return false;
        }
        catch (Exception ex)
        {
            錯誤訊息 = "驗證過程出錯：" + ex.Message;
            return false;
        }
    }

    // ── 私有方法 ──────────────────────────────────────────

    /// <summary>
    /// 檢查使用者是否為指定組別的負責人
    /// </summary>
    private static bool 是本組負責人(int 帳號編號, int 組別編號)
    {
        try
        {
            var dt = 資料庫輔助.查詢(
                @"SELECT COUNT(*) AS 計數 FROM 組別設定 
                  WHERE 組別編號=@組別 AND 負責人帳號編號=@帳號",
                資料庫輔助.P("@組別", 組別編號),
                資料庫輔助.P("@帳號", 帳號編號));

            return dt.Rows.Count > 0 && Convert.ToInt32(dt.Rows[0]["計數"]) > 0;
        }
        catch
        {
            return false;
        }
    }
}
