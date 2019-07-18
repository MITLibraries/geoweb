class MitDownloadController < ApplicationController
  def file
    key = [params[:id], params[:format]].join('.')

    redirect_to presign_this(key)
  end

  # https://docs.aws.amazon.com/sdk-for-ruby/v3/api/Aws/S3/Presigner.html
  def presign_this(layer_id_s)
    # for minio
    if Rails.env.test? || Rails.env.development?
      Aws.config[:s3] = { endpoint: ENV['MINIO_URL'], force_path_style: true }
    end

    signer = Aws::S3::Presigner.new
    signer.presigned_url(:get_object, bucket: ENV['AWS_S3_BUCKET'],
                                      key: layer_id_s,
                                      expires_in: 900)
  end
end
