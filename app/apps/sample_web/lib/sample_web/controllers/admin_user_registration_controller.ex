defmodule SampleWeb.AdminUserRegistrationController do
  use SampleWeb, :controller

  alias Sample.Admin
  alias Sample.Admin.AdminUser
  alias SampleWeb.AdminUserAuth

  def new(conn, _params) do
    changeset = Admin.change_admin_user_registration(%AdminUser{})
    render(conn, "new.html", changeset: changeset)
  end

  def create(conn, %{"admin_user" => admin_user_params}) do
    case Admin.register_admin_user(admin_user_params) do
      {:ok, admin_user} ->
        {:ok, _} =
          Admin.deliver_admin_user_confirmation_instructions(
            admin_user,
            &Routes.admin_user_confirmation_url(conn, :edit, &1)
          )

        conn
        |> put_flash(:info, "Admin user created successfully.")
        |> AdminUserAuth.log_in_admin_user(admin_user)

      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, "new.html", changeset: changeset)
    end
  end
end
