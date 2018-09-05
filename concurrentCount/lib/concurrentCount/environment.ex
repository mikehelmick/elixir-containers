defmodule ConcurrentCount.Environment do

  defp parse_int_env(nil, default) do
    default
  end
  defp parse_int_env(val_s, default) do
    case Integer.parse(val_s) do
      {x, _} when is_integer(x) -> x
      _ -> default
    end
  end

  def get_int_env(name, default) do
    parse_int_env(System.get_env(name), default)
  end

  defp parse_bool_env(tf, _) when is_boolean(tf) do
    tf
  end
  defp parse_bool_env(_, default) do
    default
  end

  def get_bool_env(name, default) do
    parse_bool_env(System.get_env(name), default)
  end
end
