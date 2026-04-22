using System;
using System.Data;
using System.IO;
using System.Web.UI.WebControls;

/// <summary>
/// 檔案上傳 v2 - 支援四層導航（區域 → 組別 → 課別 → 資料夾）與分享連結
/// 功能：
/// 1. 選擇時效區或永久區
/// 2. 選擇組別（根據權限篩選）
/// 3. 選擇課別（根據權限篩選）
/// 4. 選擇資料夾
/// 5. 上傳檔案（含安全檢查）
/// 6. 生成分享連結
/// </summary>
public partial class 檔案上傳 : System.Web.UI.Page
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
            ddl資料夾.Items.Clear();
            return;
        }

        載入組別();
    }

    /// <summary>
    /// 載入組別清單
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
            ddl資料夾.Items.Clear();
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
            ddl資料夾.Items.Clear();
            return;
        }

        載入課別();
    }

    /// <summary>
    /// 載入課別清單
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

            ddl資料夾.Items.Clear();
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
            ddl資料夾.Items.Clear();
            return;
        }

        載入資料夾();
    }

    /// <summary>
    /// 載入資料夾清單
    /// </summary>
    private void 載入資料夾()
    {
        try
        {
            int 課別編號 = Convert.ToInt32(ddl課別.SelectedValue);

            DataTable dt = 資料庫輔助.查詢(
                @"SELECT 資料夾編號, 資料夾名稱 
                  FROM 資料夾 
                  WHERE 課別編號=@課別 AND 是否刪除=0
                  ORDER BY 資料夾名稱",
                資料庫輔助.P("@課別", 課別編號)
            );

            ddl資料夾.DataSource = dt;
            ddl資料夾.DataTextField = "資料夾名稱";
            ddl資料夾.DataValueField = "資料夾編號";
            ddl資料夾.DataBind();

            ddl資料夾.Items.Insert(0, new ListItem("-- 請選擇 --", ""));
        }
        catch (Exception ex)
        {
            顯示訊息("載入資料夾失敗：" + ex.Message, "error");
        }
    }

    /// <summary>
    /// 新增資料夾按鈕事件
    /// </summary>
    protected void btn新增資料夾_Click(object sender, EventArgs e)
    {
        try
        {
            if (string.IsNullOrEmpty(ddl課別.SelectedValue))
            {
                顯示訊息("請先選擇課別", "error");
                return;
            }

            string 區域 = ddl區域.SelectedValue;
            int 組別編號 = Convert.ToInt32(ddl組別.SelectedValue);
            int 課別編號 = Convert.ToInt32(ddl課別.SelectedValue);
            string 資料夾名稱 = txt新資料夾名稱.Text.Trim();

            if (string.IsNullOrEmpty(資料夾名稱))
            {
                顯示訊息("資料夾名稱不可為空", "error");
                return;
            }

            // 檢查權限
            if (區域 == "永久區" && !權限輔助.可操作永久區(組別編號, 課別編號))
            {
                權限輔助.記錄權限拒絕(string.Format("嘗試在永久區新增資料夾"));
                顯示訊息("您沒有權限在永久區新增資料夾", "error");
                return;
            }

            if (區域 == "時效區" && !權限輔助.可操作時效區())
            {
                顯示訊息("您沒有權限在時效區新增資料夾", "error");
                return;
            }

            // 新增資料夾到資料庫
            資料庫輔助.執行(
                @"INSERT INTO 資料夾 (儲存區類型, 組別編號, 課別編號, 資料夾名稱, 建立者帳號, 建立時間)
                  VALUES (@區域, @組別, @課別, @名稱, @帳號, GETDATE())",
                資料庫輔助.P("@區域", 區域),
                資料庫輔助.P("@組別", 組別編號),
                資料庫輔助.P("@課別", 課別編號),
                資料庫輔助.P("@名稱", 資料夾名稱),
                資料庫輔助.P("@帳號", Session["登入帳號"].ToString())
            );

            // 同步到檔案系統
            同步資料夾到磁碟(區域, 組別編號, 課別編號, 資料夾名稱);

            操作紀錄輔助.記錄(null, "新增", IP輔助.取得用戶端IP(), "成功", null, null,
                string.Format("新增資料夾: 區域={0} 組別={1} 課別={2} 名稱={3}", 區域, 組別編號, 課別編號, 資料夾名稱));

            txt新資料夾名稱.Text = "";
            顯示訊息("資料夾已新增", "success");
            載入資料夾();
        }
        catch (Exception ex)
        {
            顯示訊息("新增資料夾失敗：" + ex.Message, "error");
        }
    }

    /// <summary>
    /// 上傳檔案按鈕事件
    /// </summary>
    protected void btn上傳_Click(object sender, EventArgs e)
    {
        try
        {
            // 驗證選擇
            if (string.IsNullOrEmpty(ddl區域.SelectedValue) ||
                string.IsNullOrEmpty(ddl組別.SelectedValue) ||
                string.IsNullOrEmpty(ddl課別.SelectedValue) ||
                string.IsNullOrEmpty(ddl資料夾.SelectedValue))
            {
                顯示訊息("請完整選擇區域、組別、課別和資料夾", "error");
                return;
            }

            if (!fu檔案.HasFile)
            {
                顯示訊息("請選擇要上傳的檔案", "error");
                return;
            }

            string 區域 = ddl區域.SelectedValue;
            int 組別編號 = Convert.ToInt32(ddl組別.SelectedValue);
            int 課別編號 = Convert.ToInt32(ddl課別.SelectedValue);
            int 資料夾編號 = Convert.ToInt32(ddl資料夾.SelectedValue);

            // 檢查權限
            if (區域 == "永久區" && !權限輔助_v2.可操作永久區(組別編號, 課別編號))
            {
                權限輔助_v2.記錄權限拒絕(string.Format("嘗試在永久區上傳檔案"));
                顯示訊息("您沒有權限在永久區上傳檔案", "error");
                return;
            }

            if (區域 == "時效區" && !權限輔助_v2.可操作時效區())
            {
                顯示訊息("您沒有權限在時效區上傳檔案", "error");
                return;
            }

            // 驗證檔案安全性
            if (!安全輔助.驗證上傳檔案(fu檔案.FileName, fu檔案.ContentType))
            {
                顯示訊息("檔案類型不被允許", "error");
                return;
            }

            // 取得檔案資訊
            string 原始檔名 = Path.GetFileName(fu檔案.FileName);
            string 副檔名 = Path.GetExtension(原始檔名);
            long 檔案大小 = fu檔案.PostedFile.ContentLength;

            // 檢查檔案大小
            long 最大大小 = 100 * 1024 * 1024; // 100MB
            if (檔案大小 > 最大大小)
            {
                顯示訊息("檔案大小超過限制（最大 100MB）", "error");
                return;
            }

            // 生成唯一檔名
            string 新檔名 = Guid.NewGuid().ToString() + 副檔名;

            // 取得儲存路徑
            DataTable dtGroup = 資料庫輔助.查詢(
                "SELECT 組別代碼 FROM 組別設定 WHERE 組別編號=@編號",
                資料庫輔助.P("@編號", 組別編號)
            );

            DataTable dtDept = 資料庫輔助.查詢(
                "SELECT 課別代碼 FROM 課別設定 WHERE 課別編號=@編號",
                資料庫輔助.P("@編號", 課別編號)
            );

            DataTable dtFolder = 資料庫輔助.查詢(
                "SELECT 資料夾名稱 FROM 資料夾 WHERE 資料夾編號=@編號",
                資料庫輔助.P("@編號", 資料夾編號)
            );

            if (dtGroup.Rows.Count == 0 || dtDept.Rows.Count == 0 || dtFolder.Rows.Count == 0)
            {
                顯示訊息("資料夾資訊不完整", "error");
                return;
            }

            string 組別代碼 = dtGroup.Rows[0]["組別代碼"].ToString();
            string 課別代碼 = dtDept.Rows[0]["課別代碼"].ToString();
            string 資料夾名稱 = dtFolder.Rows[0]["資料夾名稱"].ToString();

            string 根路徑 = System.Configuration.ConfigurationManager.AppSettings["儲存根路徑"] ?? @"D:\儲存區";
            string 檔案路徑 = Path.Combine(根路徑, 區域, 組別代碼, 課別代碼, 資料夾名稱, 新檔名);

            // 確保目錄存在
            Directory.CreateDirectory(Path.GetDirectoryName(檔案路徑));

            // 儲存檔案
            fu檔案.SaveAs(檔案路徑);

            // 計算到期時間（時效區 30 天）
            DateTime 到期時間 = 區域 == "時效區" ? DateTime.Now.AddDays(30) : DateTime.MaxValue;

            // 新增檔案記錄到資料庫
            資料庫輔助.執行(
                @"INSERT INTO 檔案主檔 (儲存區類型, 組別編號, 課別編號, 資料夾編號, 檔案名稱, 
                                      原始檔名, 檔案路徑, 檔案大小, 上傳者帳號, 上傳時間, 
                                      到期時間, 審核狀態, 是否刪除)
                  VALUES (@區域, @組別, @課別, @資料夾, @檔名, @原始檔名, @路徑, @大小, 
                          @帳號, GETDATE(), @到期, @審核, 0)",
                資料庫輔助.P("@區域", 區域),
                資料庫輔助.P("@組別", 組別編號),
                資料庫輔助.P("@課別", 課別編號),
                資料庫輔助.P("@資料夾", 資料夾編號),
                資料庫輔助.P("@檔名", 新檔名),
                資料庫輔助.P("@原始檔名", 原始檔名),
                資料庫輔助.P("@路徑", 檔案路徑),
                資料庫輔助.P("@大小", 檔案大小),
                資料庫輔助.P("@帳號", Session["登入帳號"].ToString()),
                資料庫輔助.P("@到期", 到期時間),
                資料庫輔助.P("@審核", 區域 == "永久區" ? "待審核" : "不需審核")
            );

            // 記錄操作
            操作紀錄輔助.記錄(null, "上傳", IP輔助.取得用戶端IP(), "成功", null, null,
                string.Format("上傳檔案: 區域={0} 組別={1} 課別={2} 資料夾={3} 檔名={4} 大小={5}MB",
                    區域, 組別編號, 課別編號, 資料夾編號, 原始檔名, 檔案大小 / 1024 / 1024));

            // 清空表單
            fu檔案.Value = "";
            txt分享連結有效期.Text = "7";

            string 訊息 = string.Format("檔案已上傳成功。");
            if (區域 == "時效區")
                訊息 += string.Format("此檔案將在 30 天後自動移到回收桶。");
            else
                訊息 += "此檔案需要審核通過才能被他人看到。";

            顯示訊息(訊息, "success");
            載入資料夾();
        }
        catch (Exception ex)
        {
            顯示訊息("上傳檔案失敗：" + ex.Message, "error");
        }
    }

    /// <summary>
    /// 同步資料夾到磁碟
    /// </summary>
    private void 同步資料夾到磁碟(string 區域, int 組別編號, int 課別編號, string 資料夾名稱)
    {
        try
        {
            // 取得組別代碼和課別代碼
            DataTable dtGroup = 資料庫輔助.查詢(
                "SELECT 組別代碼 FROM 組別設定 WHERE 組別編號=@編號",
                資料庫輔助.P("@編號", 組別編號)
            );

            DataTable dtDept = 資料庫輔助.查詢(
                "SELECT 課別代碼 FROM 課別設定 WHERE 課別編號=@編號",
                資料庫輔助.P("@編號", 課別編號)
            );

            if (dtGroup.Rows.Count == 0 || dtDept.Rows.Count == 0)
                return;

            string 組別代碼 = dtGroup.Rows[0]["組別代碼"].ToString();
            string 課別代碼 = dtDept.Rows[0]["課別代碼"].ToString();
            string 根路徑 = System.Configuration.ConfigurationManager.AppSettings["儲存根路徑"] ?? @"D:\儲存區";

            string 資料夾路徑 = System.IO.Path.Combine(根路徑, 區域, 組別代碼, 課別代碼, 資料夾名稱);

            if (!System.IO.Directory.Exists(資料夾路徑))
            {
                System.IO.Directory.CreateDirectory(資料夾路徑);
            }
        }
        catch (Exception ex)
        {
            操作紀錄輔助.記錄(null, "警告", IP輔助.取得用戶端IP(), "失敗", null, null,
                string.Format("資料夾檔案系統同步失敗: {0}", ex.Message));
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
