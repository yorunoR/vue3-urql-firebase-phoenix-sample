defmodule Sample.Admin do
  @moduledoc """
  The Admin context.
  """

  import Ecto.Query, warn: false
  alias Sample.Repo

  alias Sample.Admin.{AdminUser, AdminUserToken, AdminUserNotifier}

  ## Database getters

  @doc """
  Gets a admin_user by email.

  ## Examples

      iex> get_admin_user_by_email("foo@example.com")
      %AdminUser{}

      iex> get_admin_user_by_email("unknown@example.com")
      nil

  """
  def get_admin_user_by_email(email) when is_binary(email) do
    Repo.get_by(AdminUser, email: email)
  end

  @doc """
  Gets a admin_user by email and password.

  ## Examples

      iex> get_admin_user_by_email_and_password("foo@example.com", "correct_password")
      %AdminUser{}

      iex> get_admin_user_by_email_and_password("foo@example.com", "invalid_password")
      nil

  """
  def get_admin_user_by_email_and_password(email, password)
      when is_binary(email) and is_binary(password) do
    admin_user = Repo.get_by(AdminUser, email: email)
    if AdminUser.valid_password?(admin_user, password), do: admin_user
  end

  @doc """
  Gets a single admin_user.

  Raises `Ecto.NoResultsError` if the AdminUser does not exist.

  ## Examples

      iex> get_admin_user!(123)
      %AdminUser{}

      iex> get_admin_user!(456)
      ** (Ecto.NoResultsError)

  """
  def get_admin_user!(id), do: Repo.get!(AdminUser, id)

  ## Admin user registration

  @doc """
  Registers a admin_user.

  ## Examples

      iex> register_admin_user(%{field: value})
      {:ok, %AdminUser{}}

      iex> register_admin_user(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def register_admin_user(attrs) do
    %AdminUser{}
    |> AdminUser.registration_changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking admin_user changes.

  ## Examples

      iex> change_admin_user_registration(admin_user)
      %Ecto.Changeset{data: %AdminUser{}}

  """
  def change_admin_user_registration(%AdminUser{} = admin_user, attrs \\ %{}) do
    AdminUser.registration_changeset(admin_user, attrs, hash_password: false)
  end

  ## Settings

  @doc """
  Returns an `%Ecto.Changeset{}` for changing the admin_user email.

  ## Examples

      iex> change_admin_user_email(admin_user)
      %Ecto.Changeset{data: %AdminUser{}}

  """
  def change_admin_user_email(admin_user, attrs \\ %{}) do
    AdminUser.email_changeset(admin_user, attrs)
  end

  @doc """
  Emulates that the email will change without actually changing
  it in the database.

  ## Examples

      iex> apply_admin_user_email(admin_user, "valid password", %{email: ...})
      {:ok, %AdminUser{}}

      iex> apply_admin_user_email(admin_user, "invalid password", %{email: ...})
      {:error, %Ecto.Changeset{}}

  """
  def apply_admin_user_email(admin_user, password, attrs) do
    admin_user
    |> AdminUser.email_changeset(attrs)
    |> AdminUser.validate_current_password(password)
    |> Ecto.Changeset.apply_action(:update)
  end

  @doc """
  Updates the admin_user email using the given token.

  If the token matches, the admin_user email is updated and the token is deleted.
  The confirmed_at date is also updated to the current time.
  """
  def update_admin_user_email(admin_user, token) do
    context = "change:#{admin_user.email}"

    with {:ok, query} <- AdminUserToken.verify_change_email_token_query(token, context),
         %AdminUserToken{sent_to: email} <- Repo.one(query),
         {:ok, _} <- Repo.transaction(admin_user_email_multi(admin_user, email, context)) do
      :ok
    else
      _ -> :error
    end
  end

  defp admin_user_email_multi(admin_user, email, context) do
    changeset =
      admin_user
      |> AdminUser.email_changeset(%{email: email})
      |> AdminUser.confirm_changeset()

    Ecto.Multi.new()
    |> Ecto.Multi.update(:admin_user, changeset)
    |> Ecto.Multi.delete_all(:tokens, AdminUserToken.admin_user_and_contexts_query(admin_user, [context]))
  end

  @doc """
  Delivers the update email instructions to the given admin_user.

  ## Examples

      iex> deliver_update_email_instructions(admin_user, current_email, &Routes.admin_user_update_email_url(conn, :edit, &1))
      {:ok, %{to: ..., body: ...}}

  """
  def deliver_update_email_instructions(%AdminUser{} = admin_user, current_email, update_email_url_fun)
      when is_function(update_email_url_fun, 1) do
    {encoded_token, admin_user_token} = AdminUserToken.build_email_token(admin_user, "change:#{current_email}")

    Repo.insert!(admin_user_token)
    AdminUserNotifier.deliver_update_email_instructions(admin_user, update_email_url_fun.(encoded_token))
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for changing the admin_user password.

  ## Examples

      iex> change_admin_user_password(admin_user)
      %Ecto.Changeset{data: %AdminUser{}}

  """
  def change_admin_user_password(admin_user, attrs \\ %{}) do
    AdminUser.password_changeset(admin_user, attrs, hash_password: false)
  end

  @doc """
  Updates the admin_user password.

  ## Examples

      iex> update_admin_user_password(admin_user, "valid password", %{password: ...})
      {:ok, %AdminUser{}}

      iex> update_admin_user_password(admin_user, "invalid password", %{password: ...})
      {:error, %Ecto.Changeset{}}

  """
  def update_admin_user_password(admin_user, password, attrs) do
    changeset =
      admin_user
      |> AdminUser.password_changeset(attrs)
      |> AdminUser.validate_current_password(password)

    Ecto.Multi.new()
    |> Ecto.Multi.update(:admin_user, changeset)
    |> Ecto.Multi.delete_all(:tokens, AdminUserToken.admin_user_and_contexts_query(admin_user, :all))
    |> Repo.transaction()
    |> case do
      {:ok, %{admin_user: admin_user}} -> {:ok, admin_user}
      {:error, :admin_user, changeset, _} -> {:error, changeset}
    end
  end

  ## Session

  @doc """
  Generates a session token.
  """
  def generate_admin_user_session_token(admin_user) do
    {token, admin_user_token} = AdminUserToken.build_session_token(admin_user)
    Repo.insert!(admin_user_token)
    token
  end

  @doc """
  Gets the admin_user with the given signed token.
  """
  def get_admin_user_by_session_token(token) do
    {:ok, query} = AdminUserToken.verify_session_token_query(token)
    Repo.one(query)
  end

  @doc """
  Deletes the signed token with the given context.
  """
  def delete_session_token(token) do
    Repo.delete_all(AdminUserToken.token_and_context_query(token, "session"))
    :ok
  end

  ## Confirmation

  @doc """
  Delivers the confirmation email instructions to the given admin_user.

  ## Examples

      iex> deliver_admin_user_confirmation_instructions(admin_user, &Routes.admin_user_confirmation_url(conn, :edit, &1))
      {:ok, %{to: ..., body: ...}}

      iex> deliver_admin_user_confirmation_instructions(confirmed_admin_user, &Routes.admin_user_confirmation_url(conn, :edit, &1))
      {:error, :already_confirmed}

  """
  def deliver_admin_user_confirmation_instructions(%AdminUser{} = admin_user, confirmation_url_fun)
      when is_function(confirmation_url_fun, 1) do
    if admin_user.confirmed_at do
      {:error, :already_confirmed}
    else
      {encoded_token, admin_user_token} = AdminUserToken.build_email_token(admin_user, "confirm")
      Repo.insert!(admin_user_token)
      AdminUserNotifier.deliver_confirmation_instructions(admin_user, confirmation_url_fun.(encoded_token))
    end
  end

  @doc """
  Confirms a admin_user by the given token.

  If the token matches, the admin_user account is marked as confirmed
  and the token is deleted.
  """
  def confirm_admin_user(token) do
    with {:ok, query} <- AdminUserToken.verify_email_token_query(token, "confirm"),
         %AdminUser{} = admin_user <- Repo.one(query),
         {:ok, %{admin_user: admin_user}} <- Repo.transaction(confirm_admin_user_multi(admin_user)) do
      {:ok, admin_user}
    else
      _ -> :error
    end
  end

  defp confirm_admin_user_multi(admin_user) do
    Ecto.Multi.new()
    |> Ecto.Multi.update(:admin_user, AdminUser.confirm_changeset(admin_user))
    |> Ecto.Multi.delete_all(:tokens, AdminUserToken.admin_user_and_contexts_query(admin_user, ["confirm"]))
  end

  ## Reset password

  @doc """
  Delivers the reset password email to the given admin_user.

  ## Examples

      iex> deliver_admin_user_reset_password_instructions(admin_user, &Routes.admin_user_reset_password_url(conn, :edit, &1))
      {:ok, %{to: ..., body: ...}}

  """
  def deliver_admin_user_reset_password_instructions(%AdminUser{} = admin_user, reset_password_url_fun)
      when is_function(reset_password_url_fun, 1) do
    {encoded_token, admin_user_token} = AdminUserToken.build_email_token(admin_user, "reset_password")
    Repo.insert!(admin_user_token)
    AdminUserNotifier.deliver_reset_password_instructions(admin_user, reset_password_url_fun.(encoded_token))
  end

  @doc """
  Gets the admin_user by reset password token.

  ## Examples

      iex> get_admin_user_by_reset_password_token("validtoken")
      %AdminUser{}

      iex> get_admin_user_by_reset_password_token("invalidtoken")
      nil

  """
  def get_admin_user_by_reset_password_token(token) do
    with {:ok, query} <- AdminUserToken.verify_email_token_query(token, "reset_password"),
         %AdminUser{} = admin_user <- Repo.one(query) do
      admin_user
    else
      _ -> nil
    end
  end

  @doc """
  Resets the admin_user password.

  ## Examples

      iex> reset_admin_user_password(admin_user, %{password: "new long password", password_confirmation: "new long password"})
      {:ok, %AdminUser{}}

      iex> reset_admin_user_password(admin_user, %{password: "valid", password_confirmation: "not the same"})
      {:error, %Ecto.Changeset{}}

  """
  def reset_admin_user_password(admin_user, attrs) do
    Ecto.Multi.new()
    |> Ecto.Multi.update(:admin_user, AdminUser.password_changeset(admin_user, attrs))
    |> Ecto.Multi.delete_all(:tokens, AdminUserToken.admin_user_and_contexts_query(admin_user, :all))
    |> Repo.transaction()
    |> case do
      {:ok, %{admin_user: admin_user}} -> {:ok, admin_user}
      {:error, :admin_user, changeset, _} -> {:error, changeset}
    end
  end
end
