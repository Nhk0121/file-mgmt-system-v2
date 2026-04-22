using System;
using System.Data;
using System.Web.UI.WebControls;

/// <summary>
/// 檔案瀏覽 v2 - 支援四層導航（區域 → 組別 → 課別 → 資料夾）
/// 功能：
/// 1. 選擇時效區或永久區
/// 2. 選擇組別（根據權限篩選）
/// 3. 選擇課別（根據權限篩選）
/// 4. 瀏覽資料夾與檔案
/// 5. 新增資料夾、上傳檔案、下載檔案、刪除檔案
/// 6. 永久區檔案需要審核通過才能看到
/// </summary>
public partial class 檔案瀏覽_v2 : System.Web.UI.Page
{
    protected void Page_Load(object sender, EventArgs e)
    {
        if (Session["已登入"] == null) Response.Redirect("~/登入.aspx");

        if (!IsPostBack)
        {
            載入區域();
        }
    }

    /// <summary>
    /// 載入儲存區（時效區、永久區）
    /// </summary>
    private void 載入區域()
    {
        ddl區域.Items.Clear();
        ddl區域.Items.Add(new ListItem("-- 請選擇 --", ""));
        ddl區域.Items.Add(new ListItem("時效區", "時效區"));
        ddl區域.Items.Add(new ListItem("永久區", "永久區"));
    }

    /// <summary>
    /// 區域選擇變更事件
    /// </summary>
    protected void ddl區域_SelectedIndexChanged(object sender, EventArgs e)
    {
        if (string.IsNullOrEmpty(ddl區域.SelectedValue))
        {
            ddl組別.Items.Clear();
            ddl課別.Items.Clear();
            gv檔案.DataSource = null;
            gv檔案.DataBind();
            return;
        }

        載入組別();
    }

    /// <summary>
    /// 載入組別清單（根據使用者權限篩選）
    /// </summary>
    private void 載入組別()
    {
        try
        {
            DataTable dt = 權限輔助_v2.取得可訪問組別();

            ddl組別.DataSource = dt;
            ddl組別.DataTextField = "組別名稱";
            ddl組別.DataValueField = "組別編號";
            ddl組別.DataBind();

            ddl組別.Items.Insert(0, new ListItem("-- 請選擇 --", ""));

            ddl課別.Items.Clear();
            gv檔案.DataSource = null;
            gv檔案.DataBind();
        }
        catch (Exception ex)
        {
            顯示訊息("載入組別失敗：" + ex.Message, "error");
        }
    }

    /// <summary>
    /// 組別選擇變更事件
    /// </summary>
    protected void ddl組別_SelectedIndexChanged(object sender, EventArgs e)
    {
        if (string.IsNullOrEmpty(ddl組別.SelectedValue))
        {
            ddl課別.Items.Clear();
            gv檔案.DataSource = null;
            gv檔案.DataBind();
            return;
        }

        載入課別();
    }

    /// <summary>
    /// 載入課別清單（根據使用者權限篩選）
    /// </summary>
    private void 載入課別()
    {
        try
        {
            int 組別編號 = Convert.ToInt32(ddl組別.SelectedValue);
            DataTable dt = 權限輔助_v2.取得可訪問課別(組別編號);

            ddl課別.DataSource = dt;
            ddl課別.DataTextField = "課別名稱";
            ddl課別.DataValueField = "課別編號";
            ddl課別.DataBind();

            ddl課別.Items.Insert(0, new ListItem("-- 請選擇 --", ""));

            gv檔案.DataSource = null;
            gv檔案.DataBind();
        }
        catch (Exception ex)
        {
            顯示訊息("載入課別失敗：" + ex.Message, "error");
        }
    }

    /// <summary>
    /// 課別選擇變更事件
    /// </summary>
    protected void ddl課別_SelectedIndexChanged(object sender, EventArgs e)
    {
        if (string.IsNullOrEmpty(ddl課別.SelectedValue))
        {
            gv檔案.DataSource = null;
            gv檔案.DataBind();
            return;
        }

        載入檔案();
    }

    /// <summary>
    /// 載入檔案清單
    /// </summary>
    private void 載入檔案()
    {
        try
        {
            string 區域 = ddl區域.SelectedValue;
            int 組別編號 = Convert.ToInt32(ddl組別.SelectedValue);
            int 課別編號 = Convert.ToInt32(ddl課別.SelectedValue);

            // 檢查權限
            if (!權限輔助_v2.可訪問課別(組別編號, 課別編號))
            {
                權限輔助_v2.記錄權限拒絕(string.Format("嘗試訪問課別 {0}", 課別編號));
                顯示訊息("您沒有權限訪問此課別", "error");
                return;
            }

            // 查詢檔案
            string sql = @"
                SELECT f.*, 
                       CASE WHEN f.審核狀態=N'已通過' THEN 1 ELSE 0 END AS 可見
                FROM 檔案主檔 f
                WHERE f.儲存區類型=@區域 
                AND f.組別編號=@組別
                AND f.課別編號=@課別
                AND f.是否刪除=0";

            // 永久區：只顯示已審核通過的檔案（除非是上傳者或負責人或超管）
            if (區域 == "永久區")
            {
                if (!權限輔助_v2.是超管() && !權限輔助_v2.是負責人())
                {
                    sql += " AND (f.審核狀態=N'已通過' OR f.上傳者帳號=@帳號)";
                }
            }

            sql += " ORDER BY f.上傳時間 DESC";

            DataTable dt = 資料庫輔助.查詢(sql,
                資料庫輔助.P("@區域", 區域),
                資料庫輔助.P("@組別", 組別編號),
                資料庫輔助.P("@課別", 課別編號),
                資料庫輔助.P("@帳號", 權限輔助_v2.取得帳號編號().ToString())
            );

            gv檔案.DataSource = dt;
            gv檔案.DataBind();

            lbl檔案數.Text = string.Format("共 {0} 個檔案", dt.Rows.Count);
        }
        catch (Exception ex)
        {
            顯示訊息("載入檔案失敗：" + ex.Message, "error");
        }
    }



    /// <summary>
    /// 下載檔案事件
    /// </summary>
    protected void gv檔案_RowCommand(object sender, GridViewCommandEventArgs e)
    {
        try
        {
            if (e.CommandName == "下載")
            {
                int 檔案編號 = Convert.ToInt32(e.CommandArgument);

                // 查詢檔案資訊
                DataTable dt = 資料庫輔助.查詢(
                    "SELECT * FROM 檔案主檔 WHERE 檔案編號=@編號",
                    資料庫輔助.P("@編號", 檔案編號)
                );

                if (dt.Rows.Count == 0)
                {
                    顯示訊息("檔案不存在", "error");
                    return;
                }

                DataRow 檔案 = dt.Rows[0];

                // 檢查下載權限
                if (!權限輔助_v2.可下載檔案(檔案))
                {
                    權限輔助_v2.記錄權限拒絕(string.Format("嘗試下載檔案 {0}", 檔案編號));
                    顯示訊息("您沒有權限下載此檔案", "error");
                    return;
                }

                // 記錄下載
                操作紀錄輔助.記錄(檔案編號, "下載", IP輔助.取得用戶端IP(), "成功", null, null, null);

                // 執行下載
                string 檔案路徑 = 檔案["檔案路徑"].ToString();
                string 檔案名稱 = 檔案["檔案名稱"].ToString();

                if (System.IO.File.Exists(檔案路徑))
                {
                    Response.ContentType = "application/octet-stream";
                    Response.AddHeader("Content-Disposition", "attachment; filename=" + System.Web.HttpUtility.UrlEncode(檔案名稱));
                    Response.WriteFile(檔案路徑);
                    Response.End();
                }
                else
                {
                    顯示訊息("檔案不存在於磁碟", "error");
                }
            }
            else if (e.CommandName == "刪除")
            {
                int 檔案編號 = Convert.ToInt32(e.CommandArgument);

                // 查詢檔案資訊
                DataTable dt = 資料庫輔助.查詢(
                    "SELECT * FROM 檔案主檔 WHERE 檔案編號=@編號",
                    資料庫輔助.P("@編號", 檔案編號)
                );

                if (dt.Rows.Count == 0)
                {
                    顯示訊息("檔案不存在", "error");
                    return;
                }

                DataRow 檔案 = dt.Rows[0];

                // 檢查刪除權限
                if (!權限輔助_v2.可刪除檔案(檔案))
                {
                    權限輔助_v2.記錄權限拒絕(string.Format("嘗試刪除檔案 {0}", 檔案編號));
                    顯示訊息("您沒有權限刪除此檔案", "error");
                    return;
                }

                // 將檔案移到回收桶
                資料庫輔助.執行(
                    @"UPDATE 檔案主檔 
                      SET 儲存區類型=N'資源回收桶', 是否刪除=1, 刪除時間=GETDATE()
                      WHERE 檔案編號=@編號",
                    資料庫輔助.P("@編號", 檔案編號)
                );

                操作紀錄輔助.記錄(檔案編號, "刪除", IP輔助.取得用戶端IP(), "成功", null, null, null);

                顯示訊息("檔案已刪除", "success");
                載入檔案();
            }
        }
        catch (Exception ex)
        {
            顯示訊息("操作失敗：" + ex.Message, "error");
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
