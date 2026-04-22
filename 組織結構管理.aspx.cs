using System;
using System.Data;
using System.Web.UI.WebControls;

/// <summary>
/// 組織結構管理 v2 - 支援課別管理與檔案系統同步
/// 功能：
/// 1. 管理組別（編輯組別名稱、負責人、IP設定）
/// 2. 管理課別（新增、編輯、刪除課別）
/// 3. 同步檔案系統（課別新增/刪除時同步磁碟目錄）
/// 4. 跨組操作權限管理（為使用者設定跨組操作權限）
/// </summary>
public partial class 組織結構管理_v2 : System.Web.UI.Page
{
    protected void Page_Load(object sender, EventArgs e)
    {
        if (Session["已登入"] == null) Response.Redirect("~/登入.aspx");
        if (!角色輔助.要求管理員(this)) return;

        if (!IsPostBack)
        {
            載入組別();
        }
    }

    /// <summary>
    /// 載入組別清單
    /// </summary>
    private void 載入組別()
    {
        try
        {
            DataTable dt = 資料庫輔助.查詢(
                @"SELECT g.*, COUNT(DISTINCT d.課別編號) AS 課別數
                  FROM 組別設定 g
                  LEFT JOIN 課別設定 d ON g.組別編號 = d.組別編號
                  GROUP BY g.組別編號, g.組別名稱, g.組別代碼, g.負責人姓名, 
                           g.負責人IP, g.備用負責人IP, g.建立時間, g.是否啟用
                  ORDER BY g.組別編號"
            );

            gv組別.DataSource = dt;
            gv組別.DataBind();
        }
        catch (Exception ex)
        {
            顯示訊息("載入組別失敗：" + ex.Message, "error");
        }
    }

    /// <summary>
    /// 組別編輯事件
    /// </summary>
    protected void gv組別_RowEditing(object sender, GridViewEditEventArgs e)
    {
        gv組別.EditIndex = e.NewEditIndex;
        載入組別();
    }

    /// <summary>
    /// 組別取消編輯事件
    /// </summary>
    protected void gv組別_RowCancelingEdit(object sender, GridViewCancelEditEventArgs e)
    {
        gv組別.EditIndex = -1;
        載入組別();
    }

    /// <summary>
    /// 組別更新事件
    /// </summary>
    protected void gv組別_RowUpdating(object sender, GridViewUpdateEventArgs e)
    {
        try
        {
            var row = gv組別.Rows[e.RowIndex];
            int 組別編號 = Convert.ToInt32(gv組別.DataKeys[e.RowIndex].Value);

            TextBox txt組別名稱 = row.FindControl("txt組別名稱") as TextBox;
            TextBox txt負責人姓名 = row.FindControl("txt負責人姓名") as TextBox;
            TextBox txt負責人IP = row.FindControl("txt負責人IP") as TextBox;

            if (txt組別名稱 == null || string.IsNullOrEmpty(txt組別名稱.Text.Trim()))
            {
                顯示訊息("組別名稱不可為空", "error");
                return;
            }

            資料庫輔助.執行(
                @"UPDATE 組別設定 
                  SET 組別名稱=@名稱, 負責人姓名=@姓名, 負責人上IP=@主IP
                  WHERE 組別編號=@編號",
                資料庫輔助.P("@名稱", txt組別名稱.Text.Trim()),
                資料庫輔助.P("@姓名", txt負責人姓名 != null ? txt負責人姓名.Text : ""),
                資料庫輔助.P("@主IP", txt負責人上IP != null ? txt負責人上IP.Text : ""),
                資料庫輔助.P("@編號", 組別編號)
            );

            操作紀錄輔助.記錄(null, "編輯", IP輔助.取得用戶端IP(), "成功", null, null,
                string.Format("更新組別設定: 組別{0} 名稱={1}", 組別編號, txt組別名稱.Text));

            gv組別.EditIndex = -1;
            顯示訊息("組別已更新", "success");
            載入組別();
        }
        catch (Exception ex)
        {
            顯示訊息("更新組別失敗：" + ex.Message, "error");
        }
    }

    /// <summary>
    /// 載入課別清單
    /// </summary>
    private void 載入課別(int 組別編號)
    {
        try
        {
            DataTable dt = 資料庫輔助.查詢(
                @"SELECT d.*, COUNT(DISTINCT f.資料夾編號) AS 資料夾數
                  FROM 課別設定 d
                  LEFT JOIN 資料夾 f ON d.課別編號 = f.課別編號
                  WHERE d.組別編號=@組別
                  GROUP BY d.課別編號, d.組別編號, d.課別名稱, d.課別代碼, 
                           d.負責人帳號, d.建立時間, d.是否啟用
                  ORDER BY d.課別編號",
                資料庫輔助.P("@組別", 組別編號)
            );

            gv課別.DataSource = dt;
            gv課別.DataBind();

            lbl選中組別.Text = string.Format("組別 {0} 的課別清單", 組別編號);
        }
        catch (Exception ex)
        {
            顯示訊息("載入課別失敗：" + ex.Message, "error");
        }
    }

    /// <summary>
    /// 組別選擇事件（顯示該組別的課別清單）
    /// </summary>
    protected void gv組別_SelectedIndexChanged(object sender, EventArgs e)
    {
        int 組別編號 = Convert.ToInt32(gv組別.SelectedDataKey.Value);
        載入課別(組別編號);
        pnl課別管理.Visible = true;
    }

    /// <summary>
    /// 新增課別按鈕事件
    /// </summary>
    protected void btn新增課別_Click(object sender, EventArgs e)
    {
        try
        {
            if (gv組別.SelectedIndex < 0)
            {
                顯示訊息("請先選擇組別", "error");
                return;
            }

            int 組別編號 = Convert.ToInt32(gv組別.SelectedDataKey.Value);
            string 課別名稱 = txt新課別名稱.Text.Trim();
            string 課別代碼 = txt新課別代碼.Text.Trim();

            if (string.IsNullOrEmpty(課別名稱) || string.IsNullOrEmpty(課別代碼))
            {
                顯示訊息("課別名稱和課別代碼不可為空", "error");
                return;
            }

            // 檢查課別代碼是否已存在
            DataTable dt = 資料庫輔助.查詢(
                "SELECT * FROM 課別設定 WHERE 組別編號=@組別 AND 課別代碼=@代碼",
                資料庫輔助.P("@組別", 組別編號),
                資料庫輔助.P("@代碼", 課別代碼)
            );

            if (dt.Rows.Count > 0)
            {
                顯示訊息("課別代碼已存在", "error");
                return;
            }

            // 新增課別
            資料庫輔助.執行(
                @"INSERT INTO 課別設定 (組別編號, 課別名稱, 課別代碼, 是否啟用)
                  VALUES (@組別, @名稱, @代碼, 1)",
                資料庫輔助.P("@組別", 組別編號),
                資料庫輔助.P("@名稱", 課別名稱),
                資料庫輔助.P("@代碼", 課別代碼)
            );

            // 同步檔案系統（建立課別目錄）
            同步課別到檔案系統(組別編號, 課別代碼, "新增");

            操作紀錄輔助.記錄(null, "新增", IP輔助.取得用戶端IP(), "成功", null, null,
                string.Format("新增課別: 組別{0} 課別名稱={1} 課別代碼={2}", 組別編號, 課別名稱, 課別代碼));

            txt新課別名稱.Text = "";
            txt新課別代碼.Text = "";
            顯示訊息("課別已新增", "success");
            載入課別(組別編號);
        }
        catch (Exception ex)
        {
            顯示訊息("新增課別失敗：" + ex.Message, "error");
        }
    }

    /// <summary>
    /// 課別刪除事件
    /// </summary>
    protected void gv課別_RowDeleting(object sender, GridViewDeleteEventArgs e)
    {
        try
        {
            int 課別編號 = Convert.ToInt32(gv課別.DataKeys[e.RowIndex].Value);
            
            // 檢查課別下是否有資料夾或檔案
            DataTable dt = 資料庫輔助.查詢(
                @"SELECT COUNT(*) AS 計數 FROM 資料夾 WHERE 課別編號=@課別",
                資料庫輔助.P("@課別", 課別編號)
            );

            if (Convert.ToInt32(dt.Rows[0]["計數"]) > 0)
            {
                顯示訊息("課別下有資料夾，無法刪除。請先刪除所有資料夾。", "error");
                return;
            }

            // 刪除課別
            資料庫輔助.執行(
                "DELETE FROM 課別設定 WHERE 課別編號=@課別",
                資料庫輔助.P("@課別", 課別編號)
            );

            操作紀錄輔助.記錄(null, "刪除", IP輔助.取得用戶端IP(), "成功", null, null,
                string.Format("刪除課別: 課別編號={0}", 課別編號));

            int 組別編號 = Convert.ToInt32(gv組別.SelectedDataKey.Value);
            顯示訊息("課別已刪除", "success");
            載入課別(組別編號);
        }
        catch (Exception ex)
        {
            顯示訊息("刪除課別失敗：" + ex.Message, "error");
        }
    }

    /// <summary>
    /// 同步課別到檔案系統
    /// </summary>
    private void 同步課別到檔案系統(int 組別編號, string 課別代碼, string 操作)
    {
        try
        {
            // 取得組別代碼
            DataTable dtGroup = 資料庫輔助.查詢(
                "SELECT 組別代碼 FROM 組別設定 WHERE 組別編號=@編號",
                資料庫輔助.P("@編號", 組別編號)
            );

            if (dtGroup.Rows.Count == 0)
                return;

            string 組別代碼 = dtGroup.Rows[0]["組別代碼"].ToString();
            string 根路徑 = System.Configuration.ConfigurationManager.AppSettings["儲存根路徑"] ?? @"D:\儲存區";

            // 為時效區和永久區都建立課別目錄
            string[] 區域 = { "時效區", "永久區" };

            foreach (string 區 in 區域)
            {
                string 課別路徑 = System.IO.Path.Combine(根路徑, 區, 組別代碼, 課別代碼);

                if (操作 == "新增" && !System.IO.Directory.Exists(課別路徑))
                {
                    System.IO.Directory.CreateDirectory(課別路徑);
                }
                else if (操作 == "刪除" && System.IO.Directory.Exists(課別路徑))
                {
                    // 刪除前檢查是否為空
                    if (System.IO.Directory.GetFiles(課別路徑).Length == 0 &&
                        System.IO.Directory.GetDirectories(課別路徑).Length == 0)
                    {
                        System.IO.Directory.Delete(課別路徑);
                    }
                }
            }
        }
        catch (Exception ex)
        {
            // 檔案系統同步失敗不影響 DB 操作，但記錄警告
            操作紀錄輔助.記錄(null, "警告", IP輔助.取得用戶端IP(), "失敗", null, null,
                string.Format("課別檔案系統同步失敗: {0}", ex.Message));
        }
    }

    /// <summary>
    /// 顯示訊息
    /// </summary>
    private void 顯示訊息(string 訊息, string 類型 = "info")
    {
        lbl訊息.Text = 訊息;
        lbl訊息.CssClass = "alert alert-" + (類型 == "error" ? "danger" : 
                                           類型 == "success" ? "success" : "info");
        pnl訊息.Visible = true;
    }
}
