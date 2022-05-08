defmodule Sample.Admin.AdminUserAdmin do
  def custom_links(_schema) do
    [
      %{
        name: "Log Out",
        url: "http://localhost:4000/admin_users/log_out",
        method: :delete,
        order: 2,
        location: :top,
        icon: "sign-out-alt"
      }
    ]
  end
end
