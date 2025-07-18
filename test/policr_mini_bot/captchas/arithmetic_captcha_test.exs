defmodule PolicrMiniBot.ArithmeticCaptchaTest do
  use ExUnit.Case

  import PolicrMiniBot.ArithmeticCaptcha

  test "made/0" do
    %{candidates: candidates, correct_indices: correct_indices, question: question} =
      make!(-1, %{})

    %{"ln" => ln, "rn" => rn} = Regex.named_captures(~r/(?<ln>\d+) \+ (?<rn>\d+) = ?/, question)

    correct_answer = Enum.at(hd(candidates), hd(correct_indices) - 1)

    assert String.to_integer(ln) + String.to_integer(rn) == correct_answer
  end
end
