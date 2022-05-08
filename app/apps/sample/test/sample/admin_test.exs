defmodule Sample.AdminTest do
  use Sample.DataCase

  alias Sample.Admin

  import Sample.AdminFixtures
  alias Sample.Admin.{AdminUser, AdminUserToken}

  describe "get_admin_user_by_email/1" do
    test "does not return the admin_user if the email does not exist" do
      refute Admin.get_admin_user_by_email("unknown@example.com")
    end

    test "returns the admin_user if the email exists" do
      %{id: id} = admin_user = admin_user_fixture()
      assert %AdminUser{id: ^id} = Admin.get_admin_user_by_email(admin_user.email)
    end
  end

  describe "get_admin_user_by_email_and_password/2" do
    test "does not return the admin_user if the email does not exist" do
      refute Admin.get_admin_user_by_email_and_password("unknown@example.com", "hello world!")
    end

    test "does not return the admin_user if the password is not valid" do
      admin_user = admin_user_fixture()
      refute Admin.get_admin_user_by_email_and_password(admin_user.email, "invalid")
    end

    test "returns the admin_user if the email and password are valid" do
      %{id: id} = admin_user = admin_user_fixture()

      assert %AdminUser{id: ^id} =
               Admin.get_admin_user_by_email_and_password(admin_user.email, valid_admin_user_password())
    end
  end

  describe "get_admin_user!/1" do
    test "raises if id is invalid" do
      assert_raise Ecto.NoResultsError, fn ->
        Admin.get_admin_user!(-1)
      end
    end

    test "returns the admin_user with the given id" do
      %{id: id} = admin_user = admin_user_fixture()
      assert %AdminUser{id: ^id} = Admin.get_admin_user!(admin_user.id)
    end
  end

  describe "register_admin_user/1" do
    test "requires email and password to be set" do
      {:error, changeset} = Admin.register_admin_user(%{})

      assert %{
               password: ["can't be blank"],
               email: ["can't be blank"]
             } = errors_on(changeset)
    end

    test "validates email and password when given" do
      {:error, changeset} = Admin.register_admin_user(%{email: "not valid", password: "not valid"})

      assert %{
               email: ["must have the @ sign and no spaces"],
               password: ["should be at least 12 character(s)"]
             } = errors_on(changeset)
    end

    test "validates maximum values for email and password for security" do
      too_long = String.duplicate("db", 100)
      {:error, changeset} = Admin.register_admin_user(%{email: too_long, password: too_long})
      assert "should be at most 160 character(s)" in errors_on(changeset).email
      assert "should be at most 72 character(s)" in errors_on(changeset).password
    end

    test "validates email uniqueness" do
      %{email: email} = admin_user_fixture()
      {:error, changeset} = Admin.register_admin_user(%{email: email})
      assert "has already been taken" in errors_on(changeset).email

      # Now try with the upper cased email too, to check that email case is ignored.
      {:error, changeset} = Admin.register_admin_user(%{email: String.upcase(email)})
      assert "has already been taken" in errors_on(changeset).email
    end

    test "registers admin_users with a hashed password" do
      email = unique_admin_user_email()
      {:ok, admin_user} = Admin.register_admin_user(valid_admin_user_attributes(email: email))
      assert admin_user.email == email
      assert is_binary(admin_user.hashed_password)
      assert is_nil(admin_user.confirmed_at)
      assert is_nil(admin_user.password)
    end
  end

  describe "change_admin_user_registration/2" do
    test "returns a changeset" do
      assert %Ecto.Changeset{} = changeset = Admin.change_admin_user_registration(%AdminUser{})
      assert changeset.required == [:password, :email]
    end

    test "allows fields to be set" do
      email = unique_admin_user_email()
      password = valid_admin_user_password()

      changeset =
        Admin.change_admin_user_registration(
          %AdminUser{},
          valid_admin_user_attributes(email: email, password: password)
        )

      assert changeset.valid?
      assert get_change(changeset, :email) == email
      assert get_change(changeset, :password) == password
      assert is_nil(get_change(changeset, :hashed_password))
    end
  end

  describe "change_admin_user_email/2" do
    test "returns a admin_user changeset" do
      assert %Ecto.Changeset{} = changeset = Admin.change_admin_user_email(%AdminUser{})
      assert changeset.required == [:email]
    end
  end

  describe "apply_admin_user_email/3" do
    setup do
      %{admin_user: admin_user_fixture()}
    end

    test "requires email to change", %{admin_user: admin_user} do
      {:error, changeset} = Admin.apply_admin_user_email(admin_user, valid_admin_user_password(), %{})
      assert %{email: ["did not change"]} = errors_on(changeset)
    end

    test "validates email", %{admin_user: admin_user} do
      {:error, changeset} =
        Admin.apply_admin_user_email(admin_user, valid_admin_user_password(), %{email: "not valid"})

      assert %{email: ["must have the @ sign and no spaces"]} = errors_on(changeset)
    end

    test "validates maximum value for email for security", %{admin_user: admin_user} do
      too_long = String.duplicate("db", 100)

      {:error, changeset} =
        Admin.apply_admin_user_email(admin_user, valid_admin_user_password(), %{email: too_long})

      assert "should be at most 160 character(s)" in errors_on(changeset).email
    end

    test "validates email uniqueness", %{admin_user: admin_user} do
      %{email: email} = admin_user_fixture()

      {:error, changeset} =
        Admin.apply_admin_user_email(admin_user, valid_admin_user_password(), %{email: email})

      assert "has already been taken" in errors_on(changeset).email
    end

    test "validates current password", %{admin_user: admin_user} do
      {:error, changeset} =
        Admin.apply_admin_user_email(admin_user, "invalid", %{email: unique_admin_user_email()})

      assert %{current_password: ["is not valid"]} = errors_on(changeset)
    end

    test "applies the email without persisting it", %{admin_user: admin_user} do
      email = unique_admin_user_email()
      {:ok, admin_user} = Admin.apply_admin_user_email(admin_user, valid_admin_user_password(), %{email: email})
      assert admin_user.email == email
      assert Admin.get_admin_user!(admin_user.id).email != email
    end
  end

  describe "deliver_update_email_instructions/3" do
    setup do
      %{admin_user: admin_user_fixture()}
    end

    test "sends token through notification", %{admin_user: admin_user} do
      token =
        extract_admin_user_token(fn url ->
          Admin.deliver_update_email_instructions(admin_user, "current@example.com", url)
        end)

      {:ok, token} = Base.url_decode64(token, padding: false)
      assert admin_user_token = Repo.get_by(AdminUserToken, token: :crypto.hash(:sha256, token))
      assert admin_user_token.admin_user_id == admin_user.id
      assert admin_user_token.sent_to == admin_user.email
      assert admin_user_token.context == "change:current@example.com"
    end
  end

  describe "update_admin_user_email/2" do
    setup do
      admin_user = admin_user_fixture()
      email = unique_admin_user_email()

      token =
        extract_admin_user_token(fn url ->
          Admin.deliver_update_email_instructions(%{admin_user | email: email}, admin_user.email, url)
        end)

      %{admin_user: admin_user, token: token, email: email}
    end

    test "updates the email with a valid token", %{admin_user: admin_user, token: token, email: email} do
      assert Admin.update_admin_user_email(admin_user, token) == :ok
      changed_admin_user = Repo.get!(AdminUser, admin_user.id)
      assert changed_admin_user.email != admin_user.email
      assert changed_admin_user.email == email
      assert changed_admin_user.confirmed_at
      assert changed_admin_user.confirmed_at != admin_user.confirmed_at
      refute Repo.get_by(AdminUserToken, admin_user_id: admin_user.id)
    end

    test "does not update email with invalid token", %{admin_user: admin_user} do
      assert Admin.update_admin_user_email(admin_user, "oops") == :error
      assert Repo.get!(AdminUser, admin_user.id).email == admin_user.email
      assert Repo.get_by(AdminUserToken, admin_user_id: admin_user.id)
    end

    test "does not update email if admin_user email changed", %{admin_user: admin_user, token: token} do
      assert Admin.update_admin_user_email(%{admin_user | email: "current@example.com"}, token) == :error
      assert Repo.get!(AdminUser, admin_user.id).email == admin_user.email
      assert Repo.get_by(AdminUserToken, admin_user_id: admin_user.id)
    end

    test "does not update email if token expired", %{admin_user: admin_user, token: token} do
      {1, nil} = Repo.update_all(AdminUserToken, set: [inserted_at: ~N[2020-01-01 00:00:00]])
      assert Admin.update_admin_user_email(admin_user, token) == :error
      assert Repo.get!(AdminUser, admin_user.id).email == admin_user.email
      assert Repo.get_by(AdminUserToken, admin_user_id: admin_user.id)
    end
  end

  describe "change_admin_user_password/2" do
    test "returns a admin_user changeset" do
      assert %Ecto.Changeset{} = changeset = Admin.change_admin_user_password(%AdminUser{})
      assert changeset.required == [:password]
    end

    test "allows fields to be set" do
      changeset =
        Admin.change_admin_user_password(%AdminUser{}, %{
          "password" => "new valid password"
        })

      assert changeset.valid?
      assert get_change(changeset, :password) == "new valid password"
      assert is_nil(get_change(changeset, :hashed_password))
    end
  end

  describe "update_admin_user_password/3" do
    setup do
      %{admin_user: admin_user_fixture()}
    end

    test "validates password", %{admin_user: admin_user} do
      {:error, changeset} =
        Admin.update_admin_user_password(admin_user, valid_admin_user_password(), %{
          password: "not valid",
          password_confirmation: "another"
        })

      assert %{
               password: ["should be at least 12 character(s)"],
               password_confirmation: ["does not match password"]
             } = errors_on(changeset)
    end

    test "validates maximum values for password for security", %{admin_user: admin_user} do
      too_long = String.duplicate("db", 100)

      {:error, changeset} =
        Admin.update_admin_user_password(admin_user, valid_admin_user_password(), %{password: too_long})

      assert "should be at most 72 character(s)" in errors_on(changeset).password
    end

    test "validates current password", %{admin_user: admin_user} do
      {:error, changeset} =
        Admin.update_admin_user_password(admin_user, "invalid", %{password: valid_admin_user_password()})

      assert %{current_password: ["is not valid"]} = errors_on(changeset)
    end

    test "updates the password", %{admin_user: admin_user} do
      {:ok, admin_user} =
        Admin.update_admin_user_password(admin_user, valid_admin_user_password(), %{
          password: "new valid password"
        })

      assert is_nil(admin_user.password)
      assert Admin.get_admin_user_by_email_and_password(admin_user.email, "new valid password")
    end

    test "deletes all tokens for the given admin_user", %{admin_user: admin_user} do
      _ = Admin.generate_admin_user_session_token(admin_user)

      {:ok, _} =
        Admin.update_admin_user_password(admin_user, valid_admin_user_password(), %{
          password: "new valid password"
        })

      refute Repo.get_by(AdminUserToken, admin_user_id: admin_user.id)
    end
  end

  describe "generate_admin_user_session_token/1" do
    setup do
      %{admin_user: admin_user_fixture()}
    end

    test "generates a token", %{admin_user: admin_user} do
      token = Admin.generate_admin_user_session_token(admin_user)
      assert admin_user_token = Repo.get_by(AdminUserToken, token: token)
      assert admin_user_token.context == "session"

      # Creating the same token for another admin_user should fail
      assert_raise Ecto.ConstraintError, fn ->
        Repo.insert!(%AdminUserToken{
          token: admin_user_token.token,
          admin_user_id: admin_user_fixture().id,
          context: "session"
        })
      end
    end
  end

  describe "get_admin_user_by_session_token/1" do
    setup do
      admin_user = admin_user_fixture()
      token = Admin.generate_admin_user_session_token(admin_user)
      %{admin_user: admin_user, token: token}
    end

    test "returns admin_user by token", %{admin_user: admin_user, token: token} do
      assert session_admin_user = Admin.get_admin_user_by_session_token(token)
      assert session_admin_user.id == admin_user.id
    end

    test "does not return admin_user for invalid token" do
      refute Admin.get_admin_user_by_session_token("oops")
    end

    test "does not return admin_user for expired token", %{token: token} do
      {1, nil} = Repo.update_all(AdminUserToken, set: [inserted_at: ~N[2020-01-01 00:00:00]])
      refute Admin.get_admin_user_by_session_token(token)
    end
  end

  describe "delete_session_token/1" do
    test "deletes the token" do
      admin_user = admin_user_fixture()
      token = Admin.generate_admin_user_session_token(admin_user)
      assert Admin.delete_session_token(token) == :ok
      refute Admin.get_admin_user_by_session_token(token)
    end
  end

  describe "deliver_admin_user_confirmation_instructions/2" do
    setup do
      %{admin_user: admin_user_fixture()}
    end

    test "sends token through notification", %{admin_user: admin_user} do
      token =
        extract_admin_user_token(fn url ->
          Admin.deliver_admin_user_confirmation_instructions(admin_user, url)
        end)

      {:ok, token} = Base.url_decode64(token, padding: false)
      assert admin_user_token = Repo.get_by(AdminUserToken, token: :crypto.hash(:sha256, token))
      assert admin_user_token.admin_user_id == admin_user.id
      assert admin_user_token.sent_to == admin_user.email
      assert admin_user_token.context == "confirm"
    end
  end

  describe "confirm_admin_user/1" do
    setup do
      admin_user = admin_user_fixture()

      token =
        extract_admin_user_token(fn url ->
          Admin.deliver_admin_user_confirmation_instructions(admin_user, url)
        end)

      %{admin_user: admin_user, token: token}
    end

    test "confirms the email with a valid token", %{admin_user: admin_user, token: token} do
      assert {:ok, confirmed_admin_user} = Admin.confirm_admin_user(token)
      assert confirmed_admin_user.confirmed_at
      assert confirmed_admin_user.confirmed_at != admin_user.confirmed_at
      assert Repo.get!(AdminUser, admin_user.id).confirmed_at
      refute Repo.get_by(AdminUserToken, admin_user_id: admin_user.id)
    end

    test "does not confirm with invalid token", %{admin_user: admin_user} do
      assert Admin.confirm_admin_user("oops") == :error
      refute Repo.get!(AdminUser, admin_user.id).confirmed_at
      assert Repo.get_by(AdminUserToken, admin_user_id: admin_user.id)
    end

    test "does not confirm email if token expired", %{admin_user: admin_user, token: token} do
      {1, nil} = Repo.update_all(AdminUserToken, set: [inserted_at: ~N[2020-01-01 00:00:00]])
      assert Admin.confirm_admin_user(token) == :error
      refute Repo.get!(AdminUser, admin_user.id).confirmed_at
      assert Repo.get_by(AdminUserToken, admin_user_id: admin_user.id)
    end
  end

  describe "deliver_admin_user_reset_password_instructions/2" do
    setup do
      %{admin_user: admin_user_fixture()}
    end

    test "sends token through notification", %{admin_user: admin_user} do
      token =
        extract_admin_user_token(fn url ->
          Admin.deliver_admin_user_reset_password_instructions(admin_user, url)
        end)

      {:ok, token} = Base.url_decode64(token, padding: false)
      assert admin_user_token = Repo.get_by(AdminUserToken, token: :crypto.hash(:sha256, token))
      assert admin_user_token.admin_user_id == admin_user.id
      assert admin_user_token.sent_to == admin_user.email
      assert admin_user_token.context == "reset_password"
    end
  end

  describe "get_admin_user_by_reset_password_token/1" do
    setup do
      admin_user = admin_user_fixture()

      token =
        extract_admin_user_token(fn url ->
          Admin.deliver_admin_user_reset_password_instructions(admin_user, url)
        end)

      %{admin_user: admin_user, token: token}
    end

    test "returns the admin_user with valid token", %{admin_user: %{id: id}, token: token} do
      assert %AdminUser{id: ^id} = Admin.get_admin_user_by_reset_password_token(token)
      assert Repo.get_by(AdminUserToken, admin_user_id: id)
    end

    test "does not return the admin_user with invalid token", %{admin_user: admin_user} do
      refute Admin.get_admin_user_by_reset_password_token("oops")
      assert Repo.get_by(AdminUserToken, admin_user_id: admin_user.id)
    end

    test "does not return the admin_user if token expired", %{admin_user: admin_user, token: token} do
      {1, nil} = Repo.update_all(AdminUserToken, set: [inserted_at: ~N[2020-01-01 00:00:00]])
      refute Admin.get_admin_user_by_reset_password_token(token)
      assert Repo.get_by(AdminUserToken, admin_user_id: admin_user.id)
    end
  end

  describe "reset_admin_user_password/2" do
    setup do
      %{admin_user: admin_user_fixture()}
    end

    test "validates password", %{admin_user: admin_user} do
      {:error, changeset} =
        Admin.reset_admin_user_password(admin_user, %{
          password: "not valid",
          password_confirmation: "another"
        })

      assert %{
               password: ["should be at least 12 character(s)"],
               password_confirmation: ["does not match password"]
             } = errors_on(changeset)
    end

    test "validates maximum values for password for security", %{admin_user: admin_user} do
      too_long = String.duplicate("db", 100)
      {:error, changeset} = Admin.reset_admin_user_password(admin_user, %{password: too_long})
      assert "should be at most 72 character(s)" in errors_on(changeset).password
    end

    test "updates the password", %{admin_user: admin_user} do
      {:ok, updated_admin_user} = Admin.reset_admin_user_password(admin_user, %{password: "new valid password"})
      assert is_nil(updated_admin_user.password)
      assert Admin.get_admin_user_by_email_and_password(admin_user.email, "new valid password")
    end

    test "deletes all tokens for the given admin_user", %{admin_user: admin_user} do
      _ = Admin.generate_admin_user_session_token(admin_user)
      {:ok, _} = Admin.reset_admin_user_password(admin_user, %{password: "new valid password"})
      refute Repo.get_by(AdminUserToken, admin_user_id: admin_user.id)
    end
  end

  describe "inspect/2" do
    test "does not include password" do
      refute inspect(%AdminUser{password: "123456"}) =~ "password: \"123456\""
    end
  end
end
