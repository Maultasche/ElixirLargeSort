Mox.defmock(IntGen.IntegerFileMock, for: LargeShort.Shared.IntegerFileBehavior)

Application.put_env(:int_gen, :integer_file, IntGen.IntegerFileMock)

ExUnit.start()
